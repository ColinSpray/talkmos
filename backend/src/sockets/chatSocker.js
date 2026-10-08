const mongoose = require('mongoose');
const ChatMember = require('../models/ChatMember');
const Chat = require('../models/Chat');
const { sendPushToUser } = require('../services/fcmService');
const logger = require('../utils/logger');
const chatService = require('../modules/chats/services');
const User = require('../models/User');
const presence = require('../services/presenceService');
const lastSeen = require('../services/lastSeenService');

const CHAT_NS = 'chat';

const isChatMember = async (chatId, userId) => {
  const member = await ChatMember.findOne({ chatId, userId });
  if (member) return true;
  const chat = await Chat.findOne({ _id: chatId, deletedAt: null });
  if (chat?.chatType === 'direct') {
    return chat.sender.equals(userId) || chat.receiver.equals(userId);
  }
  return false;
};

const isUserOnline = (connectedUsers, userId) => presence.isOnline(CHAT_NS, userId);

const onlineDeviceIdsFor = (namespace, connectedUsers, userId) =>
  presence.onlineDeviceIds(CHAT_NS, userId);

const trackUser = (connectedUsers, socket) => {
  const { userId } = socket;
  if (!userId) return;
  socket.join(userId);
  if (!connectedUsers.has(userId)) connectedUsers.set(userId, new Set());
  connectedUsers.get(userId).add(socket.id);
  return presence.add(CHAT_NS, userId, socket.id, socket.deviceId);
};

const untrackUser = async (connectedUsers, socket) => {
  const { userId } = socket;
  if (!userId) return;
  const sockets = connectedUsers.get(userId);
  if (sockets) {
    sockets.delete(socket.id);
    if (sockets.size === 0) connectedUsers.delete(userId);
  }
  await presence.remove(CHAT_NS, userId, socket.id, socket.deviceId);
  if (!(await presence.isOnline(CHAT_NS, userId))) {
    await lastSeen.stamp([userId]);
  }
};

const joinChatRoom = async (socket, roomId, errorEvent) => {
  if (!roomId) return;
  try {
    const allowed = await isChatMember(roomId, socket.userId);
    if (!allowed) return socket.emit(errorEvent, { chatId: roomId, error: 'Not a member' });
    socket.join(roomId);
    socket.chatId = roomId;
    logger.info(`User ${socket.userId} joined room: ${roomId}`);
  } catch (err) {
    logger.error(`joinChatRoom error: ${err.message}`);
  }
};

const buildMedia = (mediaUrl, mediaMeta) => {
  if (!mediaUrl) return null;
  return {
    url: mediaUrl,
    thumbnail: mediaMeta?.thumbnail || '',
    size: mediaMeta?.size || 0,
    duration: mediaMeta?.duration || 0,
    mimeType: mediaMeta?.mimeType || '',
    fileName: mediaMeta?.fileName || '',
  };
};

const deliverToOne = async ({
  chatNamespace,
  connectedUsers,
  senderId,
  recipientId,
  pushUser,
  notificationsEnabled = true,
  notificationPreviewEnabled = true,
  message,
  senderName,
  clientMessageId,
}) => {
  const resolvedSenderName =
    message.senderId?.name || senderName || 'User';

  // One Redis read covers both questions — whether to emit live, and which
  // devices to leave out of the push.
  const onlineDeviceIds = await onlineDeviceIdsFor(chatNamespace, connectedUsers, recipientId);
  let deliveredLive = false;

  if (await isUserOnline(connectedUsers, recipientId)) {
    const plainMsg = typeof message.toObject === 'function' ? message.toObject() : message;
    chatNamespace.to(recipientId).emit('receive_chat_message', {
      ...plainMsg,
      senderName: resolvedSenderName,
      clientMessageId,
    });

    deliveredLive = true;

    chatNamespace.to(senderId).emit('message_delivered', {
      messageId: message._id,
      receiverId: recipientId,
      status: 'delivered',
    });
  }

  if (!pushUser || notificationsEnabled === false) return deliveredLive;

  const ATTACHMENT_LABELS = {
    image: 'Sent a photo',
    video: 'Sent a video',
    audio: 'Sent an audio message',
    voice: 'Sent a voice message',
    file: 'Sent a document',
    contact: 'Shared a contact',
    location: 'Shared their location',
    gif: 'Sent a GIF',
    sticker: 'Sent a sticker',
  };

  const body = notificationPreviewEnabled === false || message.messageType === 'text'
    ? 'Sent you a message'
    : (ATTACHMENT_LABELS[message.messageType] || `Sent a ${message.messageType} attachment`);

  // The ciphertext rides along so the device can show the actual message —
  // the server never holds the plaintext to put in the body. FCM caps a data
  // payload at 4KB, so a long one is left out and falls back to `body`.
  const MAX_PUSHED_CONTENT = 2000;
  const cipherText = String(message.content || '');
  const previewable =
    notificationPreviewEnabled !== false &&
    message.messageType === 'text' &&
    cipherText.length > 0 &&
    cipherText.length <= MAX_PUSHED_CONTENT;

  try {
    const responses = await sendPushToUser(
      pushUser,
      notificationPreviewEnabled === false ? 'New message' : senderName,
      body,
      {
        chatId: String(message.chatId),
        senderId: String(message.senderId._id || message.senderId),
        messageId: String(message._id),
        // The client renders the notification itself, so it needs the
        // display name as data rather than only as a notification title.
        senderName: notificationPreviewEnabled === false ? '' : resolvedSenderName,
        // Drawn as the notification avatar; withheld with the name when the
        // recipient has previews off.
        senderAvatar: notificationPreviewEnabled === false
          ? ''
          : String(message.senderId?.avatarUrl || ''),
        messageType: String(message.messageType || 'text'),
        content: previewable ? cipherText : '',
      },
      onlineDeviceIds
    );
    const delivered = responses.some((r) => typeof r === 'string' && r.startsWith('projects/'));
    return deliveredLive || delivered;
  } catch (err) {
    logger.error(`Push notification failed for ${recipientId}: ${err.message}`);
    return deliveredLive;
  }
};

const notifyMembers = async (
  chatNamespace,
  connectedUsers,
  members,
  senderId,
  message,
  chat,
  senderName,
  clientMessageId,
) => {
  if (members.length === 0) {
    const receiverId = String(chat.receiver) === String(senderId)
      ? String(chat.sender)
      : String(chat.receiver);

    const pushUser = await User.findById(receiverId)
      .select('notificationsEnabled notificationPreviewEnabled')
      .lean();
    const notificationsEnabled = pushUser?.notificationsEnabled;
    const notificationPreviewEnabled = pushUser?.notificationPreviewEnabled;

    const result = await Promise.allSettled([
      deliverToOne({
        chatNamespace, connectedUsers, senderId, recipientId: receiverId,
        pushUser, notificationsEnabled, notificationPreviewEnabled,
        message, senderName, clientMessageId,
      }),
    ]);
    logFailures(result, [receiverId]);
    await recordDelivery(message, result, [receiverId]);
    return;
  }

  const targets = members.filter((m) => String(m.userId._id || m.userId) !== senderId);

  const results = await Promise.allSettled(
    targets.map((m) =>
      deliverToOne({
        chatNamespace,
        connectedUsers,
        senderId,
        recipientId: String(m.userId._id || m.userId),
        pushUser: m.userId,
        notificationsEnabled: m.userId.notificationsEnabled,
        notificationPreviewEnabled: m.userId.notificationPreviewEnabled,
        message,
        senderName,
        clientMessageId,
      })
    )
  );

  const recipientIds = targets.map((m) => String(m.userId._id || m.userId));
  logFailures(results, recipientIds);
  await recordDelivery(message, results, recipientIds);
};

// Helper: log which specific recipients failed, without throwing
const logFailures = (results, recipientIds) => {
  results.forEach((r, i) => {
    if (r.status === 'rejected') {
      logger.error(`Delivery failed for ${recipientIds[i]}: ${r.reason?.message || r.reason}`);
    }
  });
};

const recordDelivery = async (message, results, recipientIds) => {
  const delivered = recipientIds.filter(
    (_, i) => results[i].status === 'fulfilled' && results[i].value === true
  );
  if (delivered.length === 0) return;

  try {
    await chatService.markDeliveredForRecipients({
      messageId: message._id,
      chatId: message.chatId,
      recipientIds: delivered,
    });
  } catch (err) {
    logger.error(`Failed to record delivery for message ${message._id}: ${err.message}`);
  }
};

const sendChatMessage = async ({ chatNamespace, connectedUsers, socket, data }) => {
  const { type, content, mediaUrl, mediaMeta, replyToId, chatId, isDirect, senderName, clientMessageId } = data;
  try {
    const { message, members, chat } = await chatService.saveMessage({
      chatId,
      senderId: socket.userId,
      type: type || 'text',
      content: content || '',
      media: buildMedia(mediaUrl, mediaMeta),
      replyToId,
      isDirect,
    });
    socket.emit('message_sent', { ...message.toObject(), clientMessageId });

    // Notify all other members
    await notifyMembers(chatNamespace, connectedUsers, members, socket.userId, message, chat, senderName, clientMessageId);
  } catch (err) {
    logger.error(`sendChatMessage error: ${err.message}`);
    socket.emit('message_error', { error: err.message });
  }
};

const markMessagesRead = async (socket, chatId, senderId) => {
  try {
    if (!chatId || !mongoose.Types.ObjectId.isValid(chatId)) return;
    const { sentReadReceipt } = await chatService.markMessagesRead({
      chatId,
      readerId: socket.userId,
      senderId,
    });
    if (!sentReadReceipt) return; // reader has read receipts off for this direct chat
    if (senderId) {
      socket.to(senderId).emit('messages_read', { readerId: socket.userId, chatId });
    } else {
      socket.to(chatId).emit('messages_read', { readerId: socket.userId, chatId });
    }
  } catch (err) {
    logger.error(`markMessagesRead error: ${err.message}`);
  }
};

const deleteChatMessage = async ({ chatNamespace, socket, data }) => {
  const { messageId, chatId, forEveryone } = data;
  try {
    const message = await chatService.deleteMessage({
      messageId,
      userId: socket.userId,
      forEveryone: !!forEveryone,
    });

    if (forEveryone) {
      const chat = await Chat.findById(chatId);
      if (chat) {
        if (chat.chatType === 'direct') {
          const participants = [String(chat.sender), String(chat.receiver)];
          await Promise.allSettled(
            participants.map((userId) =>
              chatNamespace.to(userId).emit('message_deleted', {
                messageId,
                chatId,
                forEveryone: true,
              })
            )
          );
        } else {
          const members = await ChatMember.find({ chatId, isRemoved: false }).lean();
          await Promise.allSettled(
            members.map((m) =>
              chatNamespace.to(String(m.userId._id || m.userId)).emit('message_deleted', {
                messageId,
                chatId,
                forEveryone: true,
              })
            )
          );
        }
      }
    } else {
      socket.emit('message_deleted', {
        messageId,
        chatId,
        forEveryone: false,
      });
    }
  } catch (err) {
    logger.error(`deleteChatMessage error: ${err.message}`);
    socket.emit('message_error', { error: err.message });
  }
};

const editChatMessage = async ({ chatNamespace, socket, data }) => {
  const { messageId, chatId, content } = data;
  try {
    const message = await chatService.editMessage({
      messageId,
      userId: socket.userId,
      content,
    });

    const payload = {
      messageId,
      chatId,
      content: message.content,
      edited: true,
      editedAt: message.editedAt,
    };

    const chat = await Chat.findById(chatId);
    if (chat) {
      if (chat.chatType === 'direct') {
        const participants = [String(chat.sender), String(chat.receiver)];
        await Promise.allSettled(
          participants.map((userId) => chatNamespace.to(userId).emit('message_edited', payload))
        );
      } else {
        const members = await ChatMember.find({ chatId, isRemoved: false }).lean();
        await Promise.allSettled(
          members.map((m) =>
            chatNamespace.to(String(m.userId._id || m.userId)).emit('message_edited', payload)
          )
        );
      }
    } else {
      socket.emit('message_edited', payload);
    }
  } catch (err) {
    logger.error(`editChatMessage error: ${err.message}`);
    socket.emit('message_error', { error: err.message });
  }
};

module.exports = {
  isChatMember,
  isUserOnline,
  trackUser,
  untrackUser,
  joinChatRoom,
  buildMedia,
  notifyMembers,
  sendChatMessage,
  markMessagesRead,
  deleteChatMessage,
  editChatMessage,
};
