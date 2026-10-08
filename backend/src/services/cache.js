const { getClient } = require('../config/redis');
const logger = require('../utils/logger');

/** Returns the parsed value, or null on a miss or any Redis error. */
const get = async (key) => {
  try {
    const raw = await getClient().get(key);
    return raw === null ? null : JSON.parse(raw);
  } catch (err) {
    logger.error(`[cache] get(${key}) failed: ${err.message}`);
    return null;
  }
};

/** ttlSeconds is required on purpose — an unbounded cache is how you end up debugging why a change "isn't taking effect" three deploys later. */
const set = async (key, value, ttlSeconds) => {
  try {
    await getClient().set(key, JSON.stringify(value), 'EX', ttlSeconds);
  } catch (err) {
    logger.error(`[cache] set(${key}) failed: ${err.message}`);
  }
};

const del = async (key) => {
  try {
    await getClient().del(key);
  } catch (err) {
    logger.error(`[cache] del(${key}) failed: ${err.message}`);
  }
};

module.exports = { get, set, del };
