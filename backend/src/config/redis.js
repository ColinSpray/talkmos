const Redis = require('ioredis');
const logger = require('../utils/logger');

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

let client = null;

const getClient = () => {
  if (client) return client;

  client = new Redis(REDIS_URL, {
    retryStrategy: (attempt) => Math.min(attempt * 200, 5000),
    maxRetriesPerRequest: 3,
  });

  client.on('error', (err) => logger.error(`[redis] connection error: ${err.message}`));
  client.on('connect', () => logger.info('[redis] connected'));

  return client;
};

const getPubSubClients = () => {
  const pubClient = new Redis(REDIS_URL);
  const subClient = pubClient.duplicate();
  pubClient.on('error', (err) => logger.error(`[redis:pub] error: ${err.message}`));
  subClient.on('error', (err) => logger.error(`[redis:sub] error: ${err.message}`));
  return { pubClient, subClient };
};

module.exports = { getClient, getPubSubClients };
