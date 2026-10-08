const Message = require('../../../models/Message');
const { assertMembership } = require('./helpers');

const pinMessage = async ({ messageId, userId, isPinned }) => {
  const message = await Message.findById(messageId);
  if (!message) {
    throw new Error('Message not found');
  }
  const members = await assertMembership(message.chatId, userId);

  message.isPinned = isPinned;
  message.pinnedAt = isPinned ? new Date() : null;
  await message.save();

  // Populate senderId for frontend consistency
  const populated = await Message.findById(message._id)
    .populate('senderId', 'name avatarUrl')
    .lean();

  return { message: populated, members };
};

module.exports = pinMessage;
