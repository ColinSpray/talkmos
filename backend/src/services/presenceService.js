const { getClient } = require('../config/redis');
const logger = require('../utils/logger');

const STALE_MS = 90_000;
const HEARTBEAT_MS = 30_000;

// Bounds how long a set survives with no activity at all, so a user who never
// reconnects does not leave a key behind forever.
const KEY_TTL_SECONDS = 300;

const SEP = '::';
const key = (ns, userId) => `presence:${ns}:${userId}`;
const member = (socketId, deviceId) => `${socketId}${SEP}${deviceId || ''}`;

/** Register a socket as online. Safe to call repeatedly — it doubles as the heartbeat. */
const add = async (ns, userId, socketId, deviceId) => {
  if (!userId || !socketId) return;
  const k = key(ns, String(userId));
  const now = Date.now();
  try {
    await getClient()
      .multi()
      .zadd(k, now, member(socketId, deviceId))
      .zremrangebyscore(k, '-inf', now - STALE_MS)
      .expire(k, KEY_TTL_SECONDS)
      .exec();
  } catch (err) {
    logger.error(`[presence] add(${ns}, ${userId}) failed: ${err.message}`);
  }
};

/** Deregister a socket on disconnect. */
const remove = async (ns, userId, socketId, deviceId) => {
  if (!userId || !socketId) return;
  try {
    await getClient().zrem(key(ns, String(userId)), member(socketId, deviceId));
  } catch (err) {
    logger.error(`[presence] remove(${ns}, ${userId}) failed: ${err.message}`);
  }
};

/** Live members of a user's set, stale entries excluded. */
const liveMembers = async (ns, userId) => {
  if (!userId) return [];
  try {
    return await getClient().zrangebyscore(
      key(ns, String(userId)),
      Date.now() - STALE_MS,
      '+inf'
    );
  } catch (err) {
    logger.error(`[presence] read(${ns}, ${userId}) failed: ${err.message}`);
    return [];
  }
};

/** Does this user have any live socket on this namespace, on any worker? */
const isOnline = async (ns, userId) => (await liveMembers(ns, userId)).length > 0;

const onlineDeviceIds = async (ns, userId) => {
  const ids = new Set();
  for (const m of await liveMembers(ns, userId)) {
    const deviceId = m.slice(m.indexOf(SEP) + SEP.length);
    if (deviceId) ids.add(deviceId);
  }
  return ids;
};

/** Batch form of isOnline — one round trip instead of one per user. */
const filterOnline = async (ns, userIds = []) => {
  const unique = [...new Set(userIds.map(String))].filter(Boolean);
  if (unique.length === 0) return new Set();
  const min = Date.now() - STALE_MS;
  try {
    const pipeline = getClient().multi();
    for (const id of unique) pipeline.zcount(key(ns, id), min, '+inf');
    const results = await pipeline.exec();
    const online = new Set();
    results.forEach(([err, count], i) => {
      if (!err && count > 0) online.add(unique[i]);
    });
    return online;
  } catch (err) {
    logger.error(`[presence] filterOnline(${ns}) failed: ${err.message}`);
    return new Set();
  }
};

const heartbeat = async (ns, sockets) => {
  const entries = [...sockets];
  if (entries.length === 0) return 0;
  const now = Date.now();
  try {
    const pipeline = getClient().multi();
    for (const { userId, socketId, deviceId } of entries) {
      const k = key(ns, String(userId));
      pipeline.zadd(k, now, member(socketId, deviceId));
      pipeline.expire(k, KEY_TTL_SECONDS);
    }
    await pipeline.exec();
    return entries.length;
  } catch (err) {
    logger.error(`[presence] heartbeat(${ns}) failed: ${err.message}`);
    return 0;
  }
};

const clearOwned = async (ns, sockets) => {
  const entries = [...sockets];
  if (entries.length === 0) return;
  try {
    const pipeline = getClient().multi();
    for (const { userId, socketId, deviceId } of entries) {
      pipeline.zrem(key(ns, String(userId)), member(socketId, deviceId));
    }
    await pipeline.exec();
  } catch (err) {
    logger.error(`[presence] clearOwned(${ns}) failed: ${err.message}`);
  }
};

module.exports = {
  add,
  remove,
  isOnline,
  onlineDeviceIds,
  filterOnline,
  heartbeat,
  clearOwned,
  HEARTBEAT_MS,
  STALE_MS,
};
