const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');
const { getSessionCheck } = require('../services/deviceSessionCache');
const {
  trackUser: trackChatUser,
  untrackUser: untrackChatUser,
  joinChatRoom,
  sendChatMessage,
  markMessagesRead,
  isUserOnline: isChatUserOnline,
  deleteChatMessage,
  editChatMessage,
} = require('./chatSocker');
const {
  trackUser: trackCallUser,
  untrackUser: untrackCallUser,
  initiateCall,
  joinCallRoom,
  leaveCallRoom,
  scheduleLeaveOnDisconnect,
  broadcastCallEnded,
  inviteUser,
  broadcastCallDeclined,
  broadcastCallRinging,
  getCallHistory,
  getChatCallHistory,
  getCallById,
} = require('./callSocket');
const { createLivekitToken } = require('../utils/livekitToken');
const User = require('../models/User');
const { canViewPresence } = require('../modules/users/services/privacy');
const presence = require('../services/presenceService');
const lastSeen = require('../services/lastSeenService');

const connectedChatUsers = new Map();
const connectedCallUsers = new Map();

// ─── Auth Middleware ──────────────────────────────────────────────────────────

const authenticateSocket = async (socket, next) => {
  try {
    const token =
      socket.handshake.auth?.token ||
      (socket.handshake.headers?.authorization || '').replace('Bearer ', '');
    if (!token) return next(new Error('Authentication required'));
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = String(decoded.id || decoded._id || decoded.userId);

    if (decoded.deviceId) {
      const device = await getSessionCheck(userId, decoded.deviceId);
      if (!device.found || !device.isActive || device.tokenVersion !== decoded.tokenVersion) {
        return next(new Error('Session revoked'));
      }
      socket.deviceId = decoded.deviceId;
    }

    socket.userId = userId;
    socket.data.userId = userId;
    socket.data.deviceId = socket.deviceId;
    next();
  } catch {
    next(new Error('Authentication failed'));
  }
};

const disconnectUserDevice = ({ chatNamespace, callNamespace }) => async (userId, deviceId) => {
  const kickFrom = async (namespace) => {
    try {
      const sockets = await namespace.in(String(userId)).fetchSockets();
      for (const sock of sockets) {
        if (sock.data?.deviceId === deviceId) {
          sock.emit('session_revoked', { deviceId });
          sock.disconnect(true);
        }
      }
    } catch (err) {
      logger.error(`disconnectUserDevice(${namespace.name}) failed: ${err.message}`);
    }
  };
  await Promise.all([kickFrom(chatNamespace), kickFrom(callNamespace)]);
};

// ─── Chat Namespace ───────────────────────────────────────────────────────────

const initChatNamespace = (io) => {
  const chatNamespace = io.of('/ws/chat');
  chatNamespace.use(authenticateSocket);

  chatNamespace.on('connection', (socket) => {
    logger.info(`Chat connected: ${socket.id} (user: ${socket.userId})`);
    trackChatUser(connectedChatUsers, socket);

    socket.on('join_chat', ({ chatId }) =>
      joinChatRoom(socket, chatId, 'chat_error')
    );

    socket.on('is_user_online', async ({ userId }) => {
      if (!userId) {
        socket.emit('user_online_status', { userId, online: false });
        return;
      }
      try {
        const allowed = await canViewPresence(socket.userId, userId);
        const online = allowed && (await isChatUserOnline(connectedChatUsers, userId));
        // Only sent when they are offline: while online there is nothing to
        // show, and withholding it keeps the privacy setting meaningful.
        let lastSeenAt = null;
        if (allowed && !online) {
          const user = await User.findById(userId).select('lastSeenAt').lean();
          lastSeenAt = user?.lastSeenAt || null;
        }
        socket.emit('user_online_status', { userId, online, lastSeenAt });
      } catch (err) {
        logger.error(`is_user_online error: ${err.message}`);
        socket.emit('user_online_status', { userId, online: false });
      }
    });

    socket.on('send_chat_message', (data) =>
      sendChatMessage({ chatNamespace, connectedUsers: connectedChatUsers, socket, data })
    );

    socket.on('delete_message', (data) =>
      deleteChatMessage({ chatNamespace, socket, data })
    );

    socket.on('edit_message', (data) =>
      editChatMessage({ chatNamespace, socket, data })
    );

    socket.on('messages_read', ({ chatId, senderId }) =>
      markMessagesRead(socket, chatId, senderId)
    );

    socket.on('typing', ({ conversationId }) =>
      socket.to(conversationId).emit('user_typing', { conversationId, userId: socket.userId })
    );

    socket.on('stop_typing', ({ conversationId }) =>
      socket.to(conversationId).emit('user_stop_typing', { conversationId, userId: socket.userId })
    );

    socket.on('disconnect', () => {
      logger.info(`Chat disconnected: ${socket.id}`);
      untrackChatUser(connectedChatUsers, socket);
    });
  });

  return { chatNamespace, connectedChatUsers };
};

// ─── Call Namespace ───────────────────────────────────────────────────────────

const initCallNamespace = (io) => {
  const callNamespace = io.of('/ws/call');
  callNamespace.use(authenticateSocket);

  callNamespace.on('connection', (socket) => {
    logger.info(`Call connected: ${socket.id} (user: ${socket.userId})`);
    trackCallUser(connectedCallUsers, socket);

    // Initiate a call entirely via socket (creates call, joins room, invites callee)
    socket.on('initiate_call', (data) =>
      initiateCall({ callNamespace, connectedUsers: connectedCallUsers, socket, data })
    );

    // After REST /join succeeds, client emits this to enter the signaling room
    socket.on('join_call_room', ({ callId }) =>
      joinCallRoom(socket, callId)
    );

    // After REST /leave or /end succeeds, client emits this to exit the room
    socket.on('leave_call_room', ({ callId, status }) =>
      leaveCallRoom(connectedCallUsers, socket, callId, status)
    );

    // After REST /end succeeds, broadcast to the whole room
    socket.on('end_call', ({ callId, status }) =>
      broadcastCallEnded(connectedCallUsers, socket, callId, status)
    );

    // After REST /decline succeeds, notify the room
    socket.on('decline_call', ({ callId }) =>
      broadcastCallDeclined(connectedCallUsers, socket, callId)
    );

    // Callee's device has shown the incoming-call UI and is now ringing
    socket.on('call_ringing', ({ callId }) =>
      broadcastCallRinging(socket, callId)
    );

    // Invite a specific user into a call (triggers FCM push only if offline)
    socket.on('invite_to_call', (data) =>
      inviteUser(callNamespace, connectedCallUsers, socket, data)
    );

    // Mint a LiveKit access token so the user can join the call's room. The
    // room name is the callId, so both participants join the same session.
    socket.on('get_livekit_token', async (data = {}) => {
      try {
        const room = String(data.callId || '');
        if (!room) {
          socket.emit('call_error', { error: 'callId is required for a LiveKit token' });
          return;
        }
        // From the account, not data.name — this is the name everyone else
        // sees, and a client that sends none puts a raw user id on their screen.
        const me = await User.findById(socket.userId).select('name').lean();

        const token = await createLivekitToken({
          room,
          identity: socket.userId,
          name: me?.name || data.name,
        });
        socket.emit('livekit_token', {
          callId: room,
          room,
          token,
          url: process.env.LIVEKIT_URL,
        });
      } catch (err) {
        logger.error(`get_livekit_token error: ${err.message}`);
        socket.emit('call_error', { error: err.message });
      }
    });

    socket.on('get_call_history', (data) =>
      getCallHistory(socket, data || {})
    );

    socket.on('get_chat_call_history', (data) =>
      getChatCallHistory(socket, data)
    );

    socket.on('get_call_by_id', (data) =>
      getCallById(socket, data)
    );

    socket.on('disconnect', () => {
      logger.info(`Call disconnected: ${socket.id} (user: ${socket.userId})`);
      if (socket.callId) {
        // Not a leave: a dropped socket gets a window to come back before the
        // call is finalized, which is the whole difference between reloading
        // a web client and hanging up.
        scheduleLeaveOnDisconnect(socket, socket.callId);
      }
      untrackCallUser(connectedCallUsers, socket);
    });
  });

  // Expose connectedCallUsers so the REST controller can check online status
  // before sending duplicate FCM pushes.
  return { callNamespace, connectedCallUsers };
};

// ─── Init ─────────────────────────────────────────────────────────────────────

const startPresenceHeartbeat = (chatNamespace, callNamespace) => {
  const snapshot = (namespace) => {
    const entries = [];
    for (const [socketId, sock] of namespace.sockets) {
      if (sock.userId) {
        entries.push({ userId: sock.userId, socketId, deviceId: sock.deviceId });
      }
    }
    return entries;
  };

  const tick = () => {
    const chat = snapshot(chatNamespace);
    return Promise.all([
      presence.heartbeat('chat', chat),
      presence.heartbeat('call', snapshot(callNamespace)),
      lastSeen.refresh(chat.map((entry) => entry.userId)),
    ]).catch((err) => logger.error(`presence heartbeat failed: ${err.message}`));
  };

  const timer = setInterval(tick, presence.HEARTBEAT_MS);
  // Do not hold the event loop open on shutdown.
  if (typeof timer.unref === 'function') timer.unref();

  // On a graceful stop, drop this worker's entries immediately rather than
  // leaving users to look online until their heartbeats age out.
  const cleanup = async () => {
    clearInterval(timer);
    await Promise.all([
      presence.clearOwned('chat', snapshot(chatNamespace)),
      presence.clearOwned('call', snapshot(callNamespace)),
    ]).catch(() => { });
  };
  process.once('SIGTERM', cleanup);
  process.once('SIGINT', cleanup);
};

const initTalkmosSockets = (io) => {
  const { chatNamespace, connectedChatUsers: chatUsers } = initChatNamespace(io);
  const { callNamespace, connectedCallUsers: callUsers } = initCallNamespace(io);

  startPresenceHeartbeat(chatNamespace, callNamespace);

  // Attach to the app so the REST call controller can access online status
  io.callConnectedUsers = callUsers;

  io.chatNamespace = chatNamespace;
  io.chatConnectedUsers = chatUsers;

  // Attach so the /auth/devices revoke endpoint can kick a device's live
  // sockets the moment it's logged out remotely.
  io.disconnectUserDevice = disconnectUserDevice({ chatNamespace, callNamespace });
};

module.exports = initTalkmosSockets;
