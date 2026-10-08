const Space = require('../../../models/Space');
const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');

const joinCommunity = async ({ userId, chatId }) => {
  const chat = await Chat.findOne({ _id: chatId, chatType: 'community' });
  if (!chat) {
    throw new Error('Community chat not found');
  }

  const space = await Space.findById(chat.spaceId);
  if (!space) {
    throw new Error('Space not found');
  }

  let membership = await ChatMember.findOne({ chatId: chat._id, userId });
  if (membership) {
    if (membership.isRemoved) {
      membership.isRemoved = false;
      membership.leftAt = null;
      membership.joinedAt = new Date();
      await membership.save();
    }
    return membership;
  }

  membership = await ChatMember.create({
    chatId: chat._id,
    userId,
    role: 'member',
  });

  return membership;
};

module.exports = joinCommunity;