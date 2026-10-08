const Message = require('../../../models/Message.js');

const getMessages = async ({ chatId, userId, limit = 20, before = null, after = null }) => {
  const query = { chatId };
  if (userId) query.deletedForMe = { $ne: userId };

  let anchor = null;
  if (!before && after) {
    anchor = await Message.findOne({ _id: after, chatId })
      .select('createdAt')
      .lean();
  }

  if (before) {
    query.createdAt = { $lt: new Date(before) };
  } else if (anchor) {
    query.createdAt = { $gt: anchor.createdAt };
  }

  const ascending = !before && !!anchor;

  const messages = await Message.find(query)
    .sort({ createdAt: ascending ? 1 : -1 })
    .limit(limit)
    .populate('senderId', 'name avatarUrl')
    .select('-__v')
    .lean();

  // Callers always want oldest-first.
  return ascending ? messages : messages.reverse();
};

module.exports = { getMessages };
