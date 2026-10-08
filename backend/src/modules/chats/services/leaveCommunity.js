const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');

const leaveCommunity = async ({ userId, chatId }) => {
  const chat = await Chat.findOne({ _id: chatId, chatType: 'community' });
  if (!chat) {
    throw new Error('Community chat not found');
  }

  const membership = await ChatMember.findOne({ chatId: chat._id, userId, isRemoved: false });
  if (!membership) {
    throw new Error('Not a member of this community');
  }

  if (membership.role === 'owner') {
    throw new Error('The owner cannot leave the community');
  }

  membership.isRemoved = true;
  membership.leftAt = new Date();
  await membership.save();

  return { success: true };
};

module.exports = leaveCommunity;
