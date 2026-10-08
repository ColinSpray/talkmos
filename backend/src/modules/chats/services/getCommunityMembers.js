const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');

const getCommunityMembers = async ({ chatId }) => {
  const chat = await Chat.findOne({ _id: chatId, chatType: 'community' });
  if (!chat) {
    throw new Error('Community chat not found');
  }

  const members = await ChatMember.find({ chatId: chat._id, isRemoved: false })
    .populate('userId', 'name username avatarUrl email status')
    .lean();

  return members;
};

module.exports = getCommunityMembers;
