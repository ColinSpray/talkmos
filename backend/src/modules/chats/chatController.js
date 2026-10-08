const chatService = require('./services');
const { notifyMembers } = require('../../sockets/chatSocker');
const Chat = require('../../models/Chat');
const Call = require('../../models/Call');
const ChatMember = require('../../models/ChatMember');
const MessageReaction = require('../../models/MessageReaction');
const StarredMessage = require('../../models/StarredMessage');
const logger = require('../../utils/logger');
const crypto = require('crypto');

// Central error responder: uses the statusCode a service throws when present,
// otherwise falls back to 500.
const handleError = (res, error) => {
  logger.error(error);
  const statusCode = error.statusCode || 500;
  return res.status(statusCode).json({ success: false, message: error.message });
};

const getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const { includeArchived, archivedOnly } = req.query;
    const conversations = await chatService.getUserConversations(userId, {
      includeArchived,
      archivedOnly,
    });
    return res.json({ success: true, data: conversations });
  } catch (error) {
    return handleError(res, error);
  }
};

const getConversationById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const conversation = await chatService.getConversationById(id, userId);
    return res.json({ success: true, data: conversation });
  } catch (error) {
    return handleError(res, error);
  }
};

const createConversation = async (req, res) => {
  try {
    const creatorId = req.user.id;
    const { type, name, participantIds, imageUrl, description, spaceId, category } = req.body;

    const { chat, isNew } = await chatService.createConversation({
      creatorId,
      type,
      name,
      participantIds,
      imageUrl: imageUrl,
      description,
      spaceId: spaceId,
      category,
    });

    return res.status(isNew ? 201 : 200).json({ success: true, data: chat, isNew });
  } catch (error) {
    return handleError(res, error);
  }
};

const updateConversation = async (req, res) => {
  try {
    const actorId = req.user.id;
    const { id } = req.params;
    const { name, image, imageUrl, description, bio } = req.body;

    const chat = await chatService.updateGroupInfo({
      chatId: id,
      actorId,
      name,
      image: image || imageUrl,
      description: description || bio,
    });
    return res.json({ success: true, data: chat });
  } catch (error) {
    return handleError(res, error);
  }
};

const addMembers = async (req, res) => {
  try {
    const actorId = req.user.id;
    const { id } = req.params; // chatId
    const { userIds } = req.body;

    const members = await chatService.addMembers({ chatId: id, actorId, userIds });
    return res.status(201).json({ success: true, data: members });
  } catch (error) {
    return handleError(res, error);
  }
};

const removeMember = async (req, res) => {
  try {
    const actorId = req.user.id;
    const { id, userId } = req.params; // chatId, target userId

    await chatService.removeMember({ chatId: id, actorId, targetUserId: userId });
    return res.json({ success: true, message: 'Member removed successfully' });
  } catch (error) {
    return handleError(res, error);
  }
};

const deleteConversation = async (req, res) => {
  try {
    const actorId = req.user.id;
    const { id } = req.params; // chatId

    const { memberIds } = await chatService.deleteConversation({ chatId: id, actorId });

    const io = req.app.get('io');
    if (io) {
      const payload = { chatId: String(id), deletedBy: String(actorId) };
      for (const memberId of memberIds) {
        io.of('/ws/chat').to(memberId).emit('conversation_deleted', payload);
      }
    }

    return res.json({ success: true, message: 'Group deleted successfully' });
  } catch (error) {
    return handleError(res, error);
  }
};

const leaveConversation = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // chatId

    await chatService.leaveConversation({ chatId: id, userId });
    return res.json({ success: true, message: 'Left chat successfully' });
  } catch (error) {
    return handleError(res, error);
  }
};
const getMessages = async (req, res) => {
  try {
    const { id } = req.params; // chatId
    const { limit, before = null, after = null } = req.query;

    const [chat, membership] = await Promise.all([
      Chat.findOne({ _id: id, deletedAt: null }),
      ChatMember.findOne({ chatId: id, userId: req.user.id, isRemoved: false }),
    ]);

    if (!chat) {
      return res.status(404).json({ success: false, message: 'Chat not found' });
    }

    let isAuthorized = !!membership;
    if (!isAuthorized && chat.chatType === 'direct') {
      isAuthorized = chat.sender.equals(req.user.id) || chat.receiver.equals(req.user.id);
    }

    if (!isAuthorized) {
      return res.status(403).json({ success: false, message: 'Not a member of this chat' });
    }

    const messages = await chatService.getMessages({ chatId: id, userId: req.user.id, limit, before, after });

    if (messages.length === 0) {
      return res.json({ success: true, data: [] });
    }

    const messageIds = messages.map((m) => m._id);

    const [allReactions, starredIds] = await Promise.all([
      MessageReaction.find({ messageId: { $in: messageIds } })
        .populate('userId', 'name')
        .lean(),
      StarredMessage.find({ messageId: { $in: messageIds }, userId: req.user.id }).distinct('messageId'),
    ]);

    const reactionsByMessage = new Map();
    for (const r of allReactions) {
      const key = String(r.messageId);
      const arr = reactionsByMessage.get(key);
      if (arr) arr.push(r);
      else reactionsByMessage.set(key, [r]);
    }
    const starredSet = new Set(starredIds.map(String));

    const enriched = messages.map((msg) => ({
      ...msg,
      reactions: reactionsByMessage.get(String(msg._id)) || [],
      isStarred: starredSet.has(String(msg._id)),
    }));

    return res.json({ success: true, data: enriched });
  } catch (error) {
    return handleError(res, error);
  }
};

const getSharedMedia = async (req, res) => {
  try {
    const { id } = req.params; // chatId
    const { limit, before = null } = req.query;

    const [chat, membership] = await Promise.all([
      Chat.findOne({ _id: id, deletedAt: null }),
      ChatMember.findOne({ chatId: id, userId: req.user.id, isRemoved: false }),
    ]);

    if (!chat) {
      return res.status(404).json({ success: false, message: 'Chat not found' });
    }

    let isAuthorized = !!membership;
    if (!isAuthorized && chat.chatType === 'direct') {
      isAuthorized = chat.sender.equals(req.user.id) || chat.receiver.equals(req.user.id);
    }

    if (!isAuthorized) {
      return res.status(403).json({ success: false, message: 'Not a member of this chat' });
    }

    const { items, total } = await chatService.getSharedMedia({
      chatId: id,
      userId: req.user.id,
      limit,
      before,
    });

    return res.json({ success: true, data: items, total });
  } catch (error) {
    return handleError(res, error);
  }
};

const sendMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { id } = req.params; // chatId
    const {
      messageType,
      content = '',
      media: incomingMedia,
      mediaUrl,
      mediaMeta,
      replyToId,
    } = req.body;

    const messageTypeValue = messageType || 'text';

    let media = null;
    const mediaPayload = incomingMedia || (mediaUrl ? { url: mediaUrl } : null);
    if (mediaPayload) {
      media = {
        url: mediaPayload.url || mediaPayload.mediaUrl || mediaUrl || '',
        thumbnail: mediaPayload.thumbnail || mediaMeta?.thumbnail || '',
        size: mediaPayload.size || mediaMeta?.size || 0,
        duration: mediaPayload.duration || mediaMeta?.duration || 0,
        mimeType: mediaPayload.mimeType || mediaMeta?.mimeType || '',
        fileName: mediaPayload.fileName || mediaMeta?.fileName || '',
      };
    }

    const { message, members, chat } = await chatService.saveMessage({
      chatId: id,
      senderId,
      type: messageTypeValue,
      content,
      media,
      replyToId,
    });

    const io = req.app.get('io');
    if (io && io.chatNamespace) {
      await notifyMembers(io.chatNamespace, io.chatConnectedUsers, members, senderId, message, chat);
    }

    return res.status(201).json({ success: true, data: message });
  } catch (error) {
    return handleError(res, error);
  }
};

const markDelivered = async (req, res) => {
  try {
    const receiverId = req.user.id;
    const { id } = req.params; // messageId

    const message = await chatService.markMessageDelivered({ messageId: id, receiverId });

    const io = req.app.get('io');
    if (io && message) {
      io.of('/ws/chat').to(String(message.senderId)).emit('message_delivered', {
        messageId: String(message._id),
        receiverId: String(receiverId),
        status: 'delivered',
      });
    }

    return res.json({ success: true, data: message });
  } catch (error) {
    return handleError(res, error);
  }
};

const markRead = async (req, res) => {
  try {
    const readerId = req.user.id;
    const { id } = req.params; // chatId
    const { senderId } = req.body;

    const result = await chatService.markMessagesRead({ chatId: id, readerId, senderId });

    const io = req.app.get('io');
    if (io) {
      io.of('/ws/chat').to(id).emit('messages_read', { chatId: id, readerId });
    }

    return res.json({ success: true, data: result });
  } catch (error) {
    return handleError(res, error);
  }
};

const setConversationPreferences = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // chatId
    const { isPinned, isMuted, isArchived, hidden } = req.body;

    const member = await chatService.updateMemberPreferences({
      chatId: id,
      userId,
      isPinned,
      isMuted,
      isArchived,
      hidden,
    });

    return res.json({ success: true, data: member });
  } catch (error) {
    return handleError(res, error);
  }
};

const reactToMessage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // messageId
    const { emoji } = req.body;

    const result = await chatService.reactToMessage({ messageId: id, userId, emoji });

    // Broadcast to everyone in the chat room so reactions appear in real time.
    // `emoji` is null when the reaction was removed.
    const io = req.app.get('io');
    if (io && result.chatId) {
      io.of('/ws/chat').to(String(result.chatId)).emit('message_reaction', {
        chatId: String(result.chatId),
        messageId: id,
        userId,
        emoji: result.status === 'removed' ? null : emoji,
      });
    }

    return res.json({ success: true, data: result });
  } catch (error) {
    return handleError(res, error);
  }
};

const starMessage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // messageId
    const { star } = req.body;

    const result = await chatService.starMessage({ messageId: id, userId, isStarred: star });
    return res.json({ success: true, data: result });
  } catch (error) {
    return handleError(res, error);
  }
};

const pinMessage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // messageId
    const { isPinned } = req.body;

    const { message } = await chatService.pinMessage({ messageId: id, userId, isPinned });

    const io = req.app.get('io');
    if (io) {
      const payload = {
        chatId: message.chatId.toString(),
        messageId: message._id.toString(),
        isPinned,
        pinnedAt: message.pinnedAt,
        message,
      };

      const Chat = require('../../models/Chat');
      const ChatMember = require('../../models/ChatMember');
      const chat = await Chat.findById(message.chatId);
      if (chat) {
        if (chat.chatType === 'direct') {
          const participants = [String(chat.sender), String(chat.receiver)];
          participants.forEach((uid) => {
            io.of('/ws/chat').to(uid).emit('message_pinned', payload);
          });
        } else {
          const chatMembers = await ChatMember.find({ chatId: message.chatId, isRemoved: false }).lean();
          chatMembers.forEach((m) => {
            io.of('/ws/chat').to(String(m.userId._id || m.userId)).emit('message_pinned', payload);
          });
        }
      }
    }

    return res.json({ success: true, data: message });
  } catch (error) {
    return handleError(res, error);
  }
};

const updateGroupPermissions = async (req, res) => {
  try {
    const permissions = await chatService.updateGroupPermissions({
      chatId: req.params.id,
      actorId: req.user.id,
      permissions: req.body?.permissions ?? req.body ?? {},
    });
    return res.json({ success: true, data: permissions });
  } catch (error) {
    return handleError(res, error);
  }
};

const getPinnedMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // chatId

    const pinnedMessages = await chatService.getPinnedMessages({ chatId: id, userId });
    return res.json({ success: true, data: pinnedMessages });
  } catch (error) {
    return handleError(res, error);
  }
};

const deleteMessage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // messageId
    const { forEveryone } = req.body;

    await chatService.deleteMessage({ messageId: id, userId, forEveryone: !!forEveryone });
    return res.json({ success: true, message: 'Message deleted successfully' });
  } catch (error) {
    return handleError(res, error);
  }
};

const uploadMedia = async (req, res) => {
  try {
    const { fileName, mimeType } = req.body;

    const storageService = require('../../services/storageService');
    const uploadParams = await storageService.getUploadParameters({ fileName, mimeType });

    return res.status(201).json({
      success: true,
      ...uploadParams,
      fileName,
      mimeType,
    });
  } catch (error) {
    return handleError(res, error);
  }
};

// ─── COMMUNITY CONTROLLER METHODS ──────────────────────────────────────────

const getCommunities = async (req, res) => {
  try {
    const { category } = req.query;
    const userId = req.user.id;
    const spaces = await chatService.getCommunities({ category, userId });
    return res.json({ success: true, data: spaces });
  } catch (error) {
    return handleError(res, error);
  }
};

const createCommunity = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, description, iconUrl, imageUrl, category } = req.body;

    const { space, generalChat } = await chatService.createCommunity({
      userId,
      name,
      description,
      imageUrl: imageUrl || iconUrl,
      category,
    });

    return res.status(201).json({ success: true, data: { space, generalChat } });
  } catch (error) {
    return handleError(res, error);
  }
};

const joinCommunity = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // the community's chat id

    const membership = await chatService.joinCommunity({ userId, chatId: id });
    return res.json({ success: true, data: membership });
  } catch (error) {
    return handleError(res, error);
  }
};

const leaveCommunity = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // the community's chat id

    await chatService.leaveCommunity({ userId, chatId: id });
    return res.json({ success: true, message: 'Left space successfully' });
  } catch (error) {
    return handleError(res, error);
  }
};

const getCommunityMembers = async (req, res) => {
  try {
    const { id } = req.params; // the community's chat id
    const members = await chatService.getCommunityMembers({ chatId: id });
    return res.json({ success: true, data: members });
  } catch (error) {
    return handleError(res, error);
  }
};

const getCommunityPreviewHandler = async (req, res) => {
  try {
    const { id } = req.params; // the community's chat id
    const preview = await chatService.getCommunityPreview({ chatId: id, userId: req.user.id });
    return res.json({ success: true, data: preview });
  } catch (error) {
    return handleError(res, error);
  }
};

const createEvent = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // spaceId
    const { title, description, startTime, endTime, location, instant } = req.body;

    const event = await chatService.createEvent({
      userId,
      spaceId: id,
      title,
      description,
      startTime,
      endTime,
      location,
      instant,
    });

    return res.status(201).json({ success: true, data: event });
  } catch (error) {
    return handleError(res, error);
  }
};

const getEvents = async (req, res) => {
  try {
    const { id } = req.params; // spaceId
    const events = await chatService.getEvents({ spaceId: id });
    return res.json({ success: true, data: events });
  } catch (error) {
    return handleError(res, error);
  }
};

const createMeeting = async (req, res) => {
  try {
    const userId = req.user.id;
    const { type, scheduledAt } = req.body;

    const meeting = await chatService.createMeeting({ userId, type, scheduledAt });
    return res.status(201).json({ success: true, data: meeting });
  } catch (error) {
    return handleError(res, error);
  }
};

const getHomeDashboard = async (req, res) => {
  try {
    const userId = req.user.id;

    const [conversations, missedCalls, unreadData] = await Promise.all([
      chatService.getUserConversations(userId, { includeArchived: false }),
      Call.countDocuments({
        initiatedBy: { $ne: userId },
        status: 'missed',
        createdAt: { $gt: req.user.createdAt },
      }),
      chatService.getUnreadCounts(userId),
    ]);

    return res.json({
      success: true,
      summary: {
        unread_chats: unreadData.unreadChats,
        new_group_messages: unreadData.unreadGroupMsgs,
        missed_calls: missedCalls,
      },
      recent: conversations,
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getConversations,
  getConversationById,
  createConversation,
  updateConversation,
  addMembers,
  removeMember,
  deleteConversation,
  leaveConversation,
  getMessages,
  getSharedMedia,
  sendMessage,
  markDelivered,
  markRead,
  setConversationPreferences,
  reactToMessage,
  starMessage,
  deleteMessage,
  uploadMedia,
  getCommunities,
  createCommunity,
  joinCommunity,
  leaveCommunity,
  getCommunityMembers,
  getCommunityPreviewHandler,
  createEvent,
  getEvents,
  createMeeting,
  pinMessage,
  getPinnedMessages,
  updateGroupPermissions,
  getHomeDashboard
};
