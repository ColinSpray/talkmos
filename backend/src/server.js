require('dotenv').config({ override: true });

const express = require('express');
const cluster = require('cluster');
const compression = require('compression');
const cors = require('cors');
const http = require('http');
const socketio = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter');
const { setupWorker } = require('@socket.io/sticky');
const logger = require('./utils/logger');
const { connectDB } = require('./config/db');
const { getPubSubClients } = require('./config/redis');
const { initializeFirebase } = require('./services/fcmService');

const REQUIRED_ENV_VARS = ['MONGO_URI', 'JWT_SECRET', 'MESSAGE_KEY_ID'];
const missingEnvVars = REQUIRED_ENV_VARS.filter((key) => !process.env[key] && process.env[key] !== '0');
if (missingEnvVars.length > 0) {
  logger.error(`Missing required environment variables: ${missingEnvVars.join(', ')}`);
  process.exit(1);
}

const messageKeyId = Number(process.env.MESSAGE_KEY_ID);
if (!Number.isInteger(messageKeyId) || messageKeyId < 0) {
  logger.error(
    `MESSAGE_KEY_ID must be a non-negative integer, got "${process.env.MESSAGE_KEY_ID}"`
  );
  process.exit(1);
}

connectDB();

const app = express();
const server = http.createServer(app);
const io = socketio(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

const { pubClient, subClient } = getPubSubClients();
io.adapter(createAdapter(pubClient, subClient));

app.set('io', io);

// Initialize socket events with legacy compatibility + Chat/Call namespaces
const initTalkmosSockets = require('./sockets/talkmosSocket');
initTalkmosSockets(io);

if (process.env.TRUST_PROXY) {
  app.set('trust proxy', process.env.TRUST_PROXY === 'true' ? 1 : process.env.TRUST_PROXY);
}

const HTTP_LOG_LEVEL = process.env.HTTP_LOG_LEVEL || 'error';
if (HTTP_LOG_LEVEL !== 'none') {
  const logAll = HTTP_LOG_LEVEL === 'all';
  app.use((req, res, next) => {
    if (logAll) {
      logger.info(`${req.method} ${req.url}`);
      return next();
    }
    // Deferred to the response so the status code is known — this way the
    // hot path costs a listener registration instead of a log write.
    res.on('finish', () => {
      if (res.statusCode >= 400) {
        logger.warn(`${req.method} ${req.url} -> ${res.statusCode}`);
      }
    });
    next();
  });
}

app.use(compression());
app.use(cors());
// Sized for the largest legitimate payload (a 2000-entry contact sync); every
// other route's own schema caps it far lower.
const BODY_LIMIT = process.env.BODY_LIMIT || '256kb';
app.use(express.json({ limit: BODY_LIMIT }));
app.use(express.urlencoded({ extended: false, limit: BODY_LIMIT }));
initializeFirebase();

// 2. MODULAR V1 API ROUTES (Talkmos Modules)
app.use('/api/v1/auth', require('./modules/auth/authRoutes'));
app.use('/api/v1/chat', require('./modules/chats/chatRoutes'));
app.use('/api/v1/calls', require('./modules/calls/callRoutes'));
app.use('/api/v1/stories', require('./modules/stories/storyRoutes'));
app.use('/api/v1/notifications', require('./modules/notifications/notificationRoutes'));
app.use('/api/v1/admin', require('./modules/admin/adminRoutes'));
app.use('/api/v1/apk', require('./modules/apk/apkRoutes'));
app.use('/api/v1/users', require('./modules/users/userRoutes'));
app.use('/api/v1/translate', require('./modules/translate/translateRoutes'));
app.use('/api/v1/keys', require('./modules/keys/keyRoutes'));

// Welcome/Ping Route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Talkmos API Backend Gateway' });
});

app.get('/health', async (req, res) => {
  const mongoose = require('mongoose');
  const checks = { mongo: false, redis: false };

  try {
    // 1 === connected. Avoids issuing a real query on every probe.
    checks.mongo = mongoose.connection.readyState === 1;
  } catch { /* reported as false */ }

  try {
    checks.redis = (await require('./config/redis').getClient().ping()) === 'PONG';
  } catch { /* reported as false */ }

  const healthy = checks.mongo && checks.redis;
  res.status(healthy ? 200 : 503).json({
    success: healthy,
    pid: process.pid,
    uptime: Math.floor(process.uptime()),
    checks,
  });
});

const { withLock } = require('./services/lock');
const { pruneExpiredStories } = require('./modules/stories/storyController');

const PRUNE_INTERVAL_MS = 60 * 60 * 1000;
const PRUNE_LOCK_TTL_SECONDS = 10 * 60;

const runStoryPrune = () =>
  withLock('prune-expired-stories', PRUNE_LOCK_TTL_SECONDS, pruneExpiredStories)
    .catch((err) => logger.error(`Story prune failed: ${err.message}`));

runStoryPrune(); // Run on startup
setInterval(runStoryPrune, PRUNE_INTERVAL_MS); // Run hourly

const { prunePositions } = require('./modules/users/services/nearbyGeo');

const NEARBY_PRUNE_INTERVAL_MS = 10 * 60 * 1000;
const NEARBY_PRUNE_LOCK_TTL_SECONDS = 5 * 60;

const runNearbyPrune = () =>
  withLock('prune-nearby-positions', NEARBY_PRUNE_LOCK_TTL_SECONDS, prunePositions)
    .catch((err) => logger.error(`Nearby prune failed: ${err.message}`));

runNearbyPrune();
setInterval(runNearbyPrune, NEARBY_PRUNE_INTERVAL_MS);

// Error handling middleware. A body parser rejecting malformed or oversized
// JSON marks the error 4xx — without honouring that it was reported as a 500.
app.use((err, req, res, next) => {
  const thrown = err.status || err.statusCode;
  const statusCode = thrown && thrown >= 400
    ? thrown
    : (res.statusCode === 200 ? 500 : res.statusCode);

  if (statusCode >= 500) logger.error(err);

  res.status(statusCode).json({
    success: false,
    message: statusCode === 400 && err.type === 'entity.parse.failed'
      ? 'Request body is not valid JSON'
      : err.message,
    stack: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
});

const PORT = process.env.PORT || 5000;

if (cluster.isWorker) {
  setupWorker(io);
  logger.info(`Talkmos worker ${process.pid} ready`);
} else {
  server.listen(PORT, () => {
    logger.info(`Talkmos Server running on port ${PORT}`);
  });
}

const SHUTDOWN_TIMEOUT_MS = 15000;
let shuttingDown = false;

const shutdown = async (signal) => {
  if (shuttingDown) return;
  shuttingDown = true;
  logger.info(`[shutdown] ${signal} received, draining (pid ${process.pid})`);

  const forced = setTimeout(() => {
    logger.error('[shutdown] drain timed out — exiting anyway');
    process.exit(1);
  }, SHUTDOWN_TIMEOUT_MS);
  forced.unref();

  try {
    // Disconnect sockets first: they are long-lived by definition and would
    // otherwise hold server.close() open for the full timeout every time.
    io.close();

    const reapIdle = setInterval(() => {
      if (typeof server.closeIdleConnections === 'function') server.closeIdleConnections();
    }, 200);
    reapIdle.unref();

    await new Promise((resolve) => server.close(resolve));
    clearInterval(reapIdle);
    const mongoose = require('mongoose');
    await mongoose.connection.close(false);
    logger.info('[shutdown] drained cleanly');
    process.exit(0);
  } catch (err) {
    logger.error(`[shutdown] failed: ${err.message}`);
    process.exit(1);
  }
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
