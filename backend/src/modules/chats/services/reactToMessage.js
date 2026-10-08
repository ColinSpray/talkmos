const Message = require('../../../models/Message');
const MessageReaction = require('../../../models/MessageReaction');
const { assertMembership } = require('./helpers');

const reactToMessage = async ({ messageId, userId, emoji }) => {
  const message = await Message.findById(messageId);
  if (!message) throw new Error('Message not found');
  await assertMembership(message.chatId, userId);

  const chatId = message.chatId;

  if (!emoji) {
    await MessageReaction.deleteOne({ messageId, userId });
    return { status: 'removed', chatId };
  }

  await MessageReaction.deleteMany({ messageId, userId });
  const reaction = await MessageReaction.create({ messageId, userId, emoji });

  return { status: 'reacted', reaction, chatId };
};

module.exports = reactToMessage;
