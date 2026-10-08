const Chat = require('../../../models/Chat');
const { assertMembership, enrichConversation } = require('./helpers');

const getConversationById = async (chatId, userId) => {
  const membership = await assertMembership(chatId, userId);
  const chat = await Chat.findOne({ _id: chatId, deletedAt: null })
    .populate({ path: 'spaceId', select: 'name imageUrl' })
    .lean();
  if (!chat) {
    const err = new Error('Chat not found');
    err.statusCode = 404;
    throw err;
  }
  return enrichConversation(chat, userId, membership);
};

module.exports = getConversationById;
