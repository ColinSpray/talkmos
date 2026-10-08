const Message = require('../../../models/Message');
const cache = require('../../../services/cache');

const MEDIA_TYPES = ['image', 'video'];

const TOTAL_TTL_SECONDS = 60;
const totalKey = (chatId, userId) => `media:count:${chatId}:${userId}`;

const getSharedMedia = async ({ chatId, userId, limit = 30, before = null }) => {
  const baseQuery = {
    chatId,
    messageType: { $in: MEDIA_TYPES },
    deletedForEveryone: { $ne: true },
    deletedForMe: { $ne: userId },
  };
  const pageQuery = before
    ? { ...baseQuery, createdAt: { $lt: new Date(before) } }
    : baseQuery;

  // Keyed by user as well as chat: deletedForMe makes the count per-viewer.
  const key = totalKey(chatId, userId);

  const [items, cachedTotal] = await Promise.all([
    Message.find(pageQuery)
      .sort({ createdAt: -1 })
      .limit(limit)
      .select('messageType media createdAt')
      .lean(),
    cache.get(key),
  ]);

  let total = cachedTotal;
  if (typeof total !== 'number') {
    total = await Message.countDocuments(baseQuery);
    await cache.set(key, total, TOTAL_TTL_SECONDS);
  }

  return { items, total };
};

module.exports = getSharedMedia;
