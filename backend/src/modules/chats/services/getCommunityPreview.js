const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');

const getCommunityPreview = async ({ chatId, userId }) => {
  const chat = await Chat.findOne({ _id: chatId, chatType: 'community', deletedAt: null })
    .populate({ path: 'spaceId', select: 'name description imageUrl category isVerified' })
    .lean();
  if (!chat) {
    const err = new Error('Community not found');
    err.statusCode = 404;
    throw err;
  }

  const [memberCount, membership] = await Promise.all([
    ChatMember.countDocuments({ chatId: chat._id, isRemoved: false }),
    ChatMember.findOne({ chatId: chat._id, userId, isRemoved: false }).lean(),
  ]);

  return {
    _id: chat._id,
    name: chat.spaceId?.name || '',
    description: chat.spaceId?.description || '',
    imageUrl: chat.spaceId?.imageUrl || '',
    category: chat.spaceId?.category || '',
    isVerified: chat.spaceId?.isVerified || false,
    memberCount,
    isMember: !!membership,
  };
};

module.exports = getCommunityPreview;
