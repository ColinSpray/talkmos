const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const Message = require('../../../models/Message');
const UserChatPreference = require('../../../models/UserChatPreference');
const Space = require('../../../models/Space');
const User = require('../../../models/User');
const crypto = require('crypto');

const SENDER_FIELDS = 'name username avatarUrl status lastSeenAt';
const ADMIN_ROLES = ['owner', 'admin'];

// Helper to generate a meeting code (e.g., abc-defg-hij)
const generateMeetingCode = () => {
  const p1 = crypto.randomBytes(2).toString('hex');
  const p2 = crypto.randomBytes(2).toString('hex');
  const p3 = crypto.randomBytes(2).toString('hex');
  return `${p1}-${p2}-${p3}`;
};

const assertMembership = async (chatId, userId) => {
  const membership = await ChatMember.findOne({ chatId, userId, isRemoved: false });
  if (membership) {
    return membership;
  }

  // Check if direct chat where user is sender or receiver
  const chat = await Chat.findOne({ _id: chatId, deletedAt: null });
  if (chat && chat.chatType === 'direct') {
    if (chat.sender.equals(userId) || chat.receiver.equals(userId)) {
      return {
        _id: null,
        chatId: chat._id,
        userId: userId,
        role: 'member',
        isRemoved: false,
        canSendMessages: true,
      };
    }
  }

  const err = new Error('Not a member of this chat');
  err.statusCode = 403;
  throw err;
};

/// Enforces a group-level permission. When the setting is 'admins' the actor
/// must be owner/admin; 'everyone' lets any member through.
const assertPermission = (chat, membership, key) => {
  const setting = chat?.permissions?.[key] ?? 'everyone';
  if (setting !== 'admins') return;
  assertCanManage(membership);
};

const assertCanManage = (membership) => {
  if (!ADMIN_ROLES.includes(membership.role)) {
    const err = new Error('You do not have permission to perform this action');
    err.statusCode = 403;
    throw err;
  }
};

const enrichConversation = async (chat, userId, membership) => {
  const chatObj = typeof chat.toObject === 'function' ? chat.toObject() : chat;

  const spaceNeedsPopulate = chatObj.spaceId && typeof chatObj.spaceId !== 'object';
  const isDirect = chatObj.chatType === 'direct';
  const otherUserId = isDirect ? (String(chatObj.sender) === String(userId) ? chatObj.receiver : chatObj.sender) : null;

  const otherUserPromise = otherUserId
    ? User.findById(otherUserId, SENDER_FIELDS).lean()
    : Promise.resolve(null);

  const currentUserPromise = isDirect
    ? User.findById(userId, SENDER_FIELDS).lean()
    : Promise.resolve(null);

  const [participants, lastMessage, preference, populatedSpace, otherUser, currentUser] = await Promise.all([
    isDirect
      ? Promise.resolve([])
      : ChatMember.find({ chatId: chatObj._id, isRemoved: false })
          .populate('userId', SENDER_FIELDS)
          .lean(),
    Message.findOne({ chatId: chatObj._id, deletedAt: null })
      .sort({ createdAt: -1 })
      .populate('senderId', 'name avatarUrl')
      .lean(),
    UserChatPreference.findOne({ userId, chatId: chatObj._id }).lean(),
    spaceNeedsPopulate
      ? Space.findById(chatObj.spaceId, 'name imageUrl description').lean()
      : Promise.resolve(chatObj.spaceId || null),
    otherUserPromise,
    currentUserPromise,
  ]);

  const space = populatedSpace;

  let title = 'Chat';
  let image = '';
  let description = (space && space.description) || '';
  let resolvedParticipants = participants;

  if (isDirect) {
    resolvedParticipants = [];
    if (currentUser) resolvedParticipants.push({ userId: currentUser, role: 'member' });
    if (otherUser) resolvedParticipants.push({ userId: otherUser, role: 'member' });

    if (otherUser) {
      title = otherUser.name || otherUser.username || otherUser.email || 'User';
      image = otherUser.avatarUrl || '';
    } else {
      title = 'Unknown User';
    }
  } else if (chatObj.chatType === 'community') {
    title = (space && space.name) || 'Community Channel';
    image = (space && space.imageUrl) || '';
  } else if (chatObj.chatType === 'group') {
    if (space && space.name) {
      title = space.name;
      image = space.imageUrl || '';
    } else {
      const otherMembers = participants.filter(
        (p) => p.userId && String(p.userId._id) !== String(userId)
      );
      if (otherMembers.length > 0) {
        title = otherMembers
          .map((m) => m.userId.name)
          .slice(0, 3)
          .join(', ');
        if (otherMembers.length > 3) {
          title += ` and ${otherMembers.length - 3} others`;
        }
      } else {
        title = 'Group Chat';
      }
    }
  }

  return {
    ...chatObj,
    title,
    image,
    description,
    role: membership ? membership.role : null,
    permissions: chatObj.permissions ?? {},
    canSendMessages: membership ? membership.canSendMessages : false,
    isPinned: preference ? preference.isPinned : false,
    isMuted: preference ? preference.isMuted : false,
    isArchived: preference ? preference.isArchived : false,
    unreadCount: 0, // caller may overwrite with a cheaper batched count if needed
    participants: resolvedParticipants,
    lastMessage: lastMessage
      ? {
        _id: lastMessage._id,
        senderId: lastMessage.senderId,
        content: lastMessage.content || '',
        type: lastMessage.messageType,
        status: lastMessage.status,
        createdAt: lastMessage.createdAt,
      }
      : null,
  };
};

module.exports = {
  generateMeetingCode,
  assertMembership,
  assertCanManage,
  assertPermission,
  enrichConversation,
};
