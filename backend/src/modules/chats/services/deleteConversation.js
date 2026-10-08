const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const { assertMembership } = require('./helpers');

const deleteConversation = async ({ chatId, actorId }) => {
  const chat = await Chat.findOne({ _id: chatId, deletedAt: null });
  if (!chat) {
    const err = new Error('Chat not found');
    err.statusCode = 404;
    throw err;
  }

  if (chat.chatType === 'direct') {
    const err = new Error('Direct chats cannot be deleted');
    err.statusCode = 400;
    throw err;
  }

  const membership = await assertMembership(chatId, actorId);
  if (membership.role !== 'owner') {
    const err = new Error('Only the group owner can delete it');
    err.statusCode = 403;
    throw err;
  }

  // Collected before they're closed out — this is who has the group on
  // screen right now and needs telling.
  const memberIds = (
    await ChatMember.find({ chatId, isRemoved: false }).distinct('userId')
  ).map(String);

  chat.deletedAt = new Date();
  await chat.save();

  await ChatMember.updateMany(
    { chatId, isRemoved: false },
    { $set: { isRemoved: true, leftAt: new Date(), canSendMessages: false } }
  );

  return { success: true, memberIds };
};

module.exports = deleteConversation;
