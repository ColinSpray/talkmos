const User = require('../models/User');
const cache = require('./cache');

const TTL_SECONDS = 300; // 5 minutes — invalidateUser() handles real changes promptly; this just bounds staleness from any write path that misses it.
const key = (userId) => `user:${userId}`;

const getUser = async (userId) => {
  const cached = await cache.get(key(userId));
  if (cached) return cached;

  const user = await User.findById(userId).select('-password').lean();
  if (!user) return null;

  await cache.set(key(userId), user, TTL_SECONDS);
  return user;
};

const invalidateUser = (userId) => cache.del(key(userId));

module.exports = { getUser, invalidateUser };
