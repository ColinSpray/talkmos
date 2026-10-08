const Message = require('../../../models/Message');
const { assertMembership } = require('./helpers');

const getPinnedMessages = async ({ chatId, userId }) => {
  await assertMembership(chatId, userId);

  const pinnedMessages = await Message.find({
    chatId,
    isPinned: true,
    deletedForEveryone: { $ne: true },
    senderId: { $ne: null },
  })
    .sort({ pinnedAt: -1 })
    .populate('senderId', 'name avatarUrl')
    .lean();

  return pinnedMessages;
};

module.exports = getPinnedMessages;
