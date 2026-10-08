const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const Message = require('../../../models/Message');
const User = require('../../../models/User');
const { isBlockedEitherWay } = require('../../users/services/privacy');
const { assertContentLength } = require('../messageLimits');
const { keyIdOf } = require('../ciphertextEnvelope');

const assertMembership = async (chatId, userId) => {
  const membership = await ChatMember.findOne({ chatId, userId, isRemoved: false });
  if (membership) return membership;
  const err = new Error('Not a member of this chat');
  err.statusCode = 403;
  throw err;
};

const assertCanMessage = async (chat, senderId) => {
  const senderStr = String(senderId);
  const receiverId = String(chat.sender) === senderStr ? chat.receiver : chat.sender;

  if (await isBlockedEitherWay(senderId, receiverId)) {
    const err = new Error('You cannot send messages to this user');
    err.statusCode = 403;
    throw err;
  }

  // Participants of the direct chat can always message each other
  if (String(chat.sender) === senderStr || String(chat.receiver) === senderStr) return;
  // Strangers can message if the receiver has a public account
  const receiver = await User.findById(receiverId).select('isPublic').lean();
  if (receiver?.isPublic) return;
  const err = new Error('You can only message friends or public accounts');
  err.statusCode = 403;
  throw err;
};

const saveMessage = async ({
  chatId,
  senderId,
  type = 'text',
  content = '',
  media = {},
  replyToId = null,
  isDirect,
}) => {
  // Also covers the socket path, which never runs the request schema.
  assertContentLength(content);

  const chat = await Chat.findById(chatId).lean();

  if (!chat) {
    const err = new Error('Chat not found');
    err.statusCode = 404;
    throw err;
  }

  if (chat.chatType === 'direct') {
    await assertCanMessage(chat, senderId);
  } else {
    const membership = await assertMembership(chatId, senderId);
    if (!membership.canSendMessages) {
      const err = new Error('You do not have permission to send messages');
      err.statusCode = 403;
      throw err;
    }
    // Group-level lock: when only admins may post, members are blocked even
    // though their individual canSendMessages flag is still true.
    if (chat.permissions?.sendMessages === 'admins'
      && !['owner', 'admin'].includes(membership.role)) {
      const err = new Error('Only admins can send messages in this group');
      err.statusCode = 403;
      throw err;
    }
  }

  const message = await Message.create({
    chatId,
    senderId,
    messageType: type,
    content,
    keyId: keyIdOf(content),
    media: media,
    replyTo: replyToId,
    status: 'sent',
  });

  await message.populate([
    { path: 'senderId', select: '_id name username avatarUrl' },
    {
      path: 'replyTo',
      populate: { path: 'senderId', select: '_id name username avatarUrl' },
    },
  ]);

  const bumpLastMessageAt = Chat.updateOne(
    { _id: chatId },
    { $set: { lastMessageAt: message.createdAt } }
  ).exec();

  const membersQuery = isDirect
    ? Promise.resolve([])
    : ChatMember.find({
        chatId,
        isRemoved: false,
        userId: { $ne: senderId },
      })
        .populate('userId', 'notificationsEnabled notificationPreviewEnabled')
        .lean();

  const [members] = await Promise.all([membersQuery, bumpLastMessageAt]);

  return { message, members, chat };
};

module.exports = {
  saveMessage,
};
