const { getClient } = require('../config/redis');
const logger = require('../utils/logger');

const withLock = async (name, ttlSeconds, fn) => {
  const key = `lock:${name}`;
  const token = `${process.pid}:${Date.now()}`;

  let acquired = false;
  try {
    acquired = (await getClient().set(key, token, 'EX', ttlSeconds, 'NX')) === 'OK';
  } catch (err) {
    // Redis down: skip rather than run. For a cleanup job, doing nothing this
    // cycle is safer than every worker doing it at once.
    logger.error(`[lock] could not acquire ${name}: ${err.message}`);
    return undefined;
  }

  if (!acquired) return undefined;

  try {
    return await fn();
  } finally {
    // Compare-and-delete, so an overrunning job cannot release the lock a
    // different worker has since taken.
    try {
      await getClient().eval(
        'if redis.call("get", KEYS[1]) == ARGV[1] then return redis.call("del", KEYS[1]) else return 0 end',
        1,
        key,
        token
      );
    } catch (err) {
      logger.error(`[lock] could not release ${name}: ${err.message}`);
    }
  }
};

module.exports = { withLock };
