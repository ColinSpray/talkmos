const { getClient } = require('../config/redis');
const logger = require('../utils/logger');

const KEY = {
  userStories: (userId) => `stories:user:${userId}`,
  publicStories: (category) => `stories:public:${category || 'all'}`,
  viewers: (storyId) => `story:viewers:${storyId}`,
};

const PUBLIC_TTL_SECONDS = 30;

// Floor for per-story TTLs, so a story about to expire is not written with a
// zero or negative TTL (which Redis rejects).
const MIN_TTL_SECONDS = 5;

/** Seconds until the newest-expiring story in a list lapses. */
const ttlFor = (stories) => {
  const now = Date.now();
  const soonest = stories.reduce((min, s) => {
    const at = new Date(s.expiresAt).getTime();
    return Number.isFinite(at) && at < min ? at : min;
  }, Infinity);
  if (!Number.isFinite(soonest)) return MIN_TTL_SECONDS;
  return Math.max(MIN_TTL_SECONDS, Math.floor((soonest - now) / 1000));
};

const getUserStories = async (userIds = []) => {
  const ids = userIds.map(String);
  if (ids.length === 0) return { hits: new Map(), misses: [] };

  try {
    const raw = await getClient().mget(ids.map(KEY.userStories));
    const hits = new Map();
    const misses = [];
    ids.forEach((id, i) => {
      if (raw[i] == null) return misses.push(id);
      try {
        hits.set(id, JSON.parse(raw[i]));
      } catch {
        misses.push(id);
      }
    });
    return { hits, misses };
  } catch (err) {
    logger.error(`[storyCache] getUserStories failed: ${err.message}`);
    return { hits: new Map(), misses: ids };
  }
};

const setUserStories = async (byUser = new Map()) => {
  if (byUser.size === 0) return;
  try {
    const pipeline = getClient().multi();
    for (const [userId, stories] of byUser) {
      pipeline.set(
        KEY.userStories(userId),
        JSON.stringify(stories),
        'EX',
        stories.length ? ttlFor(stories) : PUBLIC_TTL_SECONDS
      );
    }
    await pipeline.exec();
  } catch (err) {
    logger.error(`[storyCache] setUserStories failed: ${err.message}`);
  }
};

const getPublicStories = async (category) => {
  try {
    const raw = await getClient().get(KEY.publicStories(category));
    return raw == null ? null : JSON.parse(raw);
  } catch (err) {
    logger.error(`[storyCache] getPublicStories failed: ${err.message}`);
    return null;
  }
};

const setPublicStories = async (category, stories) => {
  try {
    await getClient().set(
      KEY.publicStories(category),
      JSON.stringify(stories),
      'EX',
      PUBLIC_TTL_SECONDS
    );
  } catch (err) {
    logger.error(`[storyCache] setPublicStories failed: ${err.message}`);
  }
};

/** Drop an author's cached list — called on create and delete. */
const invalidateUser = async (userId) => {
  try {
    await getClient().del(KEY.userStories(String(userId)));
  } catch (err) {
    logger.error(`[storyCache] invalidateUser failed: ${err.message}`);
  }
};

const addViewer = async (storyId, viewerId, expiresAt) => {
  try {
    const ttl = ttlFor([{ expiresAt }]);
    await getClient()
      .multi()
      .sadd(KEY.viewers(storyId), String(viewerId))
      .expire(KEY.viewers(storyId), ttl)
      .exec();
  } catch (err) {
    logger.error(`[storyCache] addViewer failed: ${err.message}`);
  }
};

const filterViewed = async (storyIds = [], viewerId) => {
  if (storyIds.length === 0) return new Set();
  try {
    const pipeline = getClient().multi();
    for (const id of storyIds) pipeline.sismember(KEY.viewers(id), String(viewerId));
    const results = await pipeline.exec();
    const viewed = new Set();
    results.forEach(([err, isMember], i) => {
      if (!err && isMember) viewed.add(String(storyIds[i]));
    });
    return viewed;
  } catch (err) {
    logger.error(`[storyCache] filterViewed failed: ${err.message}`);
    return null;
  }
};

/** Warm a story's view set from Mongo, so a cold cache is not read as unviewed. */
const primeViewers = async (storyId, viewerIds = [], expiresAt) => {
  if (viewerIds.length === 0) return;
  try {
    await getClient()
      .multi()
      .sadd(KEY.viewers(storyId), ...viewerIds.map(String))
      .expire(KEY.viewers(storyId), ttlFor([{ expiresAt }]))
      .exec();
  } catch (err) {
    logger.error(`[storyCache] primeViewers failed: ${err.message}`);
  }
};

/** Remove everything belonging to deleted stories. */
const dropStories = async (storyIds = [], authorIds = [], categories = []) => {
  if (storyIds.length === 0 && authorIds.length === 0 && categories.length === 0) {
    return;
  }
  try {
    const pipeline = getClient().multi();
    for (const id of storyIds) pipeline.del(KEY.viewers(String(id)));
    for (const id of authorIds) pipeline.del(KEY.userStories(String(id)));
    // A public story is in its own category's discover list and in the
    // catch-all one, so both go — otherwise a deleted story keeps being served
    // from discover for the rest of the list's TTL.
    for (const category of new Set(categories)) {
      pipeline.del(KEY.publicStories(category));
      pipeline.del(KEY.publicStories(null));
    }
    await pipeline.exec();
  } catch (err) {
    logger.error(`[storyCache] dropStories failed: ${err.message}`);
  }
};

module.exports = {
  getUserStories,
  setUserStories,
  getPublicStories,
  setPublicStories,
  invalidateUser,
  addViewer,
  filterViewed,
  primeViewers,
  dropStories,
  PUBLIC_TTL_SECONDS,
};
