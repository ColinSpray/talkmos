const cluster = require('cluster');
const http = require('http');
const os = require('os');
const { setupMaster } = require('@socket.io/sticky');
const logger = require('./utils/logger');

const resolveWorkers = () => {
  const raw = (process.env.CLUSTER_WORKERS || '1').trim();
  if (raw.toLowerCase() !== 'auto') return parseInt(raw, 10) || 1;

  const cores = typeof os.availableParallelism === 'function'
    ? os.availableParallelism()
    : os.cpus().length;
  return Math.max(1, cores - 2);
};

const numWorkers = resolveWorkers();

if (numWorkers > 1 && cluster.isPrimary) {
  const PORT = process.env.PORT || 5000;

  logger.info(`[cluster] primary ${process.pid} starting ${numWorkers} workers`);

  const httpServer = http.createServer();
  setupMaster(httpServer, { loadBalancingMethod: 'round-robin' });

  // The sticky handoff passes connection handles over IPC, which needs the
  // advanced serializer.
  cluster.setupPrimary({ serialization: 'advanced' });

  httpServer.listen(PORT, () => {
    logger.info(`[cluster] listening on ${PORT}, routing to ${numWorkers} workers`);
  });

  for (let i = 0; i < numWorkers; i++) cluster.fork();

  let shuttingDown = false;

  cluster.on('exit', (worker, code, signal) => {
    if (shuttingDown) return;
    logger.error(`[cluster] worker ${worker.process.pid} exited (${signal || code}) — restarting`);
    cluster.fork();
  });

  const shutdown = (signal) => {
    if (shuttingDown) return;
    shuttingDown = true;
    logger.info(`[cluster] ${signal} received, stopping ${Object.keys(cluster.workers).length} workers`);

    httpServer.close();
    for (const id in cluster.workers) cluster.workers[id].kill('SIGTERM');

    const deadline = setTimeout(() => {
      logger.error('[cluster] workers did not exit in time — forcing');
      for (const id in cluster.workers) cluster.workers[id].kill('SIGKILL');
      process.exit(1);
    }, 20000);
    deadline.unref();

    const waitForExit = setInterval(() => {
      if (Object.keys(cluster.workers).length === 0) {
        clearInterval(waitForExit);
        logger.info('[cluster] all workers stopped');
        process.exit(0);
      }
    }, 200);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
} else {
  require('./server');
}
