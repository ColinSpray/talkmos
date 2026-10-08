const { RateLimiterRedis } = require('rate-limiter-flexible');
const { getClient } = require('../config/redis');
const logger = require('../utils/logger');

const rateLimiter = ({ points, duration, keyPrefix, key, refundOnFailure = false }) => {
  const limiter = new RateLimiterRedis({
    storeClient: getClient(),
    points,
    duration,
    keyPrefix,
  });

  return async (req, res, next) => {
    const consumeKey = key ? key(req) : req.ip;

    try {
      await limiter.consume(consumeKey);
    } catch (err) {
      if (err instanceof Error) {
        logger.error(`[rateLimit:${keyPrefix}] Redis error, allowing request through: ${err.message}`);
        return next();
      }
      const retrySecs = Math.max(1, Math.ceil(err.msBeforeNext / 1000));
      res.set('Retry-After', String(retrySecs));
      return res.status(429).json({ success: false, message: 'Too many requests, please try again later.' });
    }

    // Attached only on the path where a point was actually spent, so the 429
    // above — which consumed nothing — can never refund one it did not take.
    if (refundOnFailure) {
      res.on('finish', () => {
        if (res.statusCode < 400) return;
        limiter
          .reward(consumeKey)
          .catch((error) => logger.error(`[rateLimit:${keyPrefix}] refund failed: ${error.message}`));
      });
    }

    return next();
  };
};

module.exports = { rateLimiter };
