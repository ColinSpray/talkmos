const logger = require('../utils/logger');
const { sendCallNotificationToUser } = require('../services/fcmService');
const {
  emitCallEnded,
  emitCallDeclined,
  emitCallParticipantDisconnected,
  emitCallParticipantLeft,
} = require('../services/callEvents');
const User = require('../models/User');
const Call = require('../models/Call');
const CallParticipant = require('../models/CallParticipant');
const callService = require('../modules/calls/services');
const { canInitiateWith } = require('../modules/users/services/privacy');
const presence = require('../services/presenceService');

const CALL_NS = 'call';

const isUserOnline = (connectedUsers, userId) => presence.isOnline(CALL_NS, userId);

// How long a call is held open for a participant whose socket dropped. A web
// client reloading its page disconnects and comes back within a second or two;
// ending the call on the disconnect leaves them nothing to rejoin. Native apps
// keep their process (and socket) across backgrounding, so this only ever
// covers a genuine drop.
const RECONNECT_GRACE_MS = Number(process.env.CALL_RECONNECT_GRACE_MS || 15000);

// Countdowns started by a disconnect, keyed by participant. Process-local by
// nature — the stamp on the participant is what actually decides the outcome
// (see finalizeDisconnect), so a rejoin served by another process still calls
// this off and a process that dies mid-countdown only delays the leave until
// the last peer hangs up.
const pendingDisconnects = new Map();
const graceKey = (userId, callId) => `${userId}:${callId}`;

const cancelPendingLeave = (userId, callId) => {
  const key = graceKey(userId, callId);
  const timer = pendingDisconnects.get(key);
  if (!timer) return false;
  clearTimeout(timer);
  pendingDisconnects.delete(key);
  return true;
};

/**
 * A lost socket starts a countdown instead of ending the call. Rejoining
 * within it cancels the countdown; otherwise the leave runs exactly as an
 * immediate disconnect used to.
 */
const scheduleLeaveOnDisconnect = async (socket, callId) => {
  if (!callId) return;
  const { userId } = socket;
  // Captured now: by the time the countdown fires this socket is long gone,
  // and a disconnected socket is no use for broadcasting.
  const io = socket.nsp.server;

  try {
    const marked = await callService.markDisconnected({ callId, userId });
    if (!marked) return;

    cancelPendingLeave(userId, callId);
    await emitCallParticipantDisconnected(io, {
      callId,
      userId,
      reconnectWithinMs: RECONNECT_GRACE_MS,
    });

    const key = graceKey(userId, callId);
    const timer = setTimeout(async () => {
      pendingDisconnects.delete(key);
      try {
        const result = await callService.finalizeDisconnect({
          callId,
          userId,
          since: marked.disconnectedAt,
        });
        if (!result) {
          logger.info(`User ${userId} rejoined call ${callId} within the grace period`);
          return;
        }

        await emitCallParticipantLeft(io, {
          callId,
          userId,
          status: result.participant.status,
        });
        if (result.endedNow) {
          await emitCallEnded(io, { callId, status: result.call.status, actorUserId: userId });
        }
        logger.info(`User ${userId} did not rejoin call ${callId} — left`);
      } catch (err) {
        logger.error(`finalizeDisconnect error for call ${callId}: ${err.message}`);
      }
    }, RECONNECT_GRACE_MS);

    if (typeof timer.unref === 'function') timer.unref();
    pendingDisconnects.set(key, timer);
    logger.info(
      `User ${userId} disconnected from call ${callId} — holding it open for ${RECONNECT_GRACE_MS}ms`
    );
  } catch (err) {
    logger.error(`scheduleLeaveOnDisconnect error for call ${callId}: ${err.message}`);
  }
};

const callEnded = (socket, callId, status) =>
  emitCallEnded(socket.nsp.server, { callId, status, actorUserId: socket.userId });

const trackUser = (connectedUsers, socket) => {
  const { userId } = socket;
  if (!userId) return;
  socket.join(userId); // personal room for direct invites
  if (!connectedUsers.has(userId)) connectedUsers.set(userId, new Set());
  connectedUsers.get(userId).add(socket.id);
  return presence.add(CALL_NS, userId, socket.id, socket.deviceId);
};

const untrackUser = (connectedUsers, socket) => {
  const { userId } = socket;
  if (!userId) return;
  const sockets = connectedUsers.get(userId);
  if (sockets) {
    sockets.delete(socket.id);
    if (sockets.size === 0) connectedUsers.delete(userId);
  }
  return presence.remove(CALL_NS, userId, socket.id, socket.deviceId);
};

const joinCallRoom = async (socket, callId) => {
  if (!callId) return;
  try {
    const { call, participant } = await callService.joinCall({ callId, userId: socket.userId });

    cancelPendingLeave(socket.userId, callId);
    socket.join(callId);
    socket.callId = callId;
    socket.to(callId).emit('call_participant_joined', {
      callId,
      userId: socket.userId,
      participant,
    });
    logger.info(`User ${socket.userId} joined call room: ${callId}`);
  } catch (err) {
    logger.error(`joinCallRoom error: ${err.message}`);
    socket.emit('call_error', { callId, error: err.message });
  }
};

const leaveCallRoom = async (connectedUsers, socket, callId, status = 'left') => {
  if (!callId) return;
  cancelPendingLeave(socket.userId, callId);
  try {
    const { call, participant, endedNow } = await callService.leaveCall({ callId, userId: socket.userId });

    socket.to(callId).emit('call_participant_left', {
      callId,
      userId: socket.userId,
      status: participant.status,
    });

    // Only the leave that finalized the call announces it. A later disconnect
    // for the same call reaches a terminal call and stays quiet.
    if (endedNow) await callEnded(socket, callId, call.status);

    socket.leave(callId);
    socket.callId = null;
    logger.info(`User ${socket.userId} left call room: ${callId}`);
  } catch (err) {
    // If the service throws (e.g. "not in this call"), still leave the socket room
    // so the user doesn't get stuck.
    logger.error(`leaveCallRoom error: ${err.message}`);
    socket.to(callId).emit('call_participant_left', {
      callId,
      userId: socket.userId,
      status,
    });
    // The leave that should have ended the call is the one that just failed,
    // so nobody else is going to announce it — and a peer left waiting on
    // call_ended sits on a call that is already over.
    await announceIfAlreadyOver(socket, callId);
    socket.leave(callId);
    socket.callId = null;
  }
};

/// Emits call_ended when the call has reached a terminal status but the path
/// that got it there could not say so.
const announceIfAlreadyOver = async (socket, callId) => {
  try {
    const call = await Call.findById(callId).select('status').lean();
    if (!call || !CALL_TERMINAL_STATUSES.includes(call.status)) return;
    await callEnded(socket, callId, call.status);
  } catch (err) {
    logger.error(`announceIfAlreadyOver error for call ${callId}: ${err.message}`);
  }
};

const broadcastCallEnded = async (connectedUsers, socket, callId, status) => {
  if (!callId) return;
  try {
    const { call, endedNow } = await callService.endCall({
      callId,
      userId: socket.userId,
      status,
    });
    if (endedNow) await callEnded(socket, callId, call.status);
  } catch (err) {
    logger.error(`broadcastCallEnded error: ${err.message}`);
    // Still broadcast so peers can clean up even if the DB update fails
    socket.to(callId).emit('call_ended', { callId, status: status || 'ended' });
  }
};

const broadcastCallDeclined = async (connectedUsers, socket, callId) => {
  if (!callId) return;
  try {
    const { call, endedNow } = await callService.declineCall({
      callId,
      userId: socket.userId,
    });

    await emitCallDeclined(socket.nsp.server, { callId, userId: socket.userId });

    // If the service finalized the call (direct call declined), also broadcast ended
    if (endedNow) await callEnded(socket, callId, call.status);
  } catch (err) {
    logger.error(`broadcastCallDeclined error: ${err.message}`);
    socket.to(callId).emit('call_declined', { callId, userId: socket.userId });
  }
};

const broadcastCallRinging = (socket, callId) => {
  if (!callId) return;
  socket.to(callId).emit('call_ringing', { callId, userId: socket.userId });
};

const toCallDto = (call) => ({
  _id: String(call._id),
  conversationId: call.chatId ? String(call.chatId) : null,
  type: call.callType,
  scope: call.isGroupCall ? 'group' : '1:1',
  initiatorId: call.initiatedBy,
  status: call.status,
  startedAt: call.startedAt,
  // When it was answered, as against when it started ringing.
  connectedAt: call.connectedAt || null,
  endedAt: call.endedAt,
  durationSeconds: call.duration,
  participants: (call.participants || []).map((p) => ({
    _id: String(p._id),
    callId: String(p.callId),
    userId: p.userId,
    status: p.status,
    joinedAt: p.joinedAt,
    leftAt: p.leftAt,
  })),
});

const getCallHistory = async (socket, data = {}) => {
  try {
    const records = await callService.getUserCallHistory({
      userId: socket.userId,
      limit: data.limit,
    });
    socket.emit('call_history', {
      history: records.map((r) => toCallDto(r.call)),
    });
  } catch (err) {
    logger.error(`getCallHistory error: ${err.message}`);
    socket.emit('call_error', { error: err.message });
  }
};

const getChatCallHistory = async (socket, data = {}) => {
  const { chatId, limit } = data;
  try {
    const calls = await callService.getChatCallHistory({ chatId, userId: socket.userId, limit });
    socket.emit('chat_call_history', { chatId, history: calls.map(toCallDto) });
  } catch (err) {
    logger.error(`getChatCallHistory error: ${err.message}`);
    socket.emit('call_error', { error: err.message });
  }
};

const getCallById = async (socket, data = {}) => {
  const { callId } = data;
  try {
    const call = await callService.getCallById(callId, socket.userId);
    socket.emit('call_details', { call: toCallDto(call) });
  } catch (err) {
    logger.error(`getCallById error: ${err.message}`);
    socket.emit('call_error', { callId, error: err.message });
  }
};

const CALL_TERMINAL_STATUSES = ['ended', 'missed', 'declined', 'failed'];

const inviteUser = async (callNamespace, connectedUsers, socket, { calleeId, callId, callType, initiatorName }) => {
  if (!calleeId || !callId) return;

  if (!(await canInitiateWith(socket.userId, calleeId))) {
    logger.info(
      `invite_to_call refused: ${socket.userId} may not ring ${calleeId}`
    );
    // Flagged non-fatal: the invite failed, the call carries on. Without the
    // code the caller's client treats any error on its call id as the call
    // itself failing, and hangs up on everyone.
    socket.emit('call_error', {
      callId,
      code: 'invite_refused',
      fatal: false,
      error: 'You cannot add this user to the call',
    });
    return;
  }

  try {
    const call = await Call.findById(callId);
    if (call && !CALL_TERMINAL_STATUSES.includes(call.status)) {
      await CallParticipant.updateOne(
        { callId, userId: calleeId },
        { $setOnInsert: { callId, userId: calleeId }, $set: { status: 'ringing' } },
        { upsert: true }
      );
      const count = await CallParticipant.countDocuments({ callId });
      if (!call.isGroupCall && count > 2) {
        call.isGroupCall = true;
        await call.save();
      }
    }
  } catch (err) {
    logger.error(`invite_to_call participant add failed: ${err.message}`);
  }

  // Always emit via socket (covers the case where callee is connected)
  callNamespace.to(calleeId).emit('incoming_call', {
    callId,
    callType,
    initiatorId: socket.userId,
    initiatorName,
  });

  // Only send FCM push if the callee is NOT connected to the call namespace
  if (await isUserOnline(connectedUsers, calleeId)) {
    logger.info(`Callee ${calleeId} is online on call namespace — skipping FCM push`);
    return;
  }

  try {
    const callee = await User.findById(calleeId).select('_id').lean();
    if (callee) {
      await sendCallNotificationToUser(callee, {
        callId: String(callId),
        callType: String(callType),
        initiatorId: String(socket.userId),
        initiatorName: initiatorName || 'Someone',
      });
    }
  } catch (err) {
    logger.error(`FCM call invite failed for ${calleeId}: ${err.message}`);
  }
};

const initiateCall = async ({ callNamespace, connectedUsers, socket, data }) => {
  const { chatId, callType, calleeName, initiatorName } = data;
  try {
    // 1. Create the call + participants in DB
    const { call, participants } = await callService.initiateCall({
      chatId,
      callerId: socket.userId,
      callType,
    });

    const callId = String(call._id);

    // 2. Join the caller into the signaling room
    socket.join(callId);
    socket.callId = callId;
    logger.info(`User ${socket.userId} initiated and joined call room: ${callId}`);

    // 3. Emit call_initiated back to the caller with the full data
    socket.emit('call_initiated', {
      call: call.toObject(),
      participants,
    });

    // 4. Invite every other participant (covers group calls, not just 1:1).
    const callees = participants
      .map((p) => String(p.userId._id || p.userId))
      .filter((uid) => uid && uid !== String(socket.userId));

    for (const calleeId of callees) {
      // Emit incoming_call to the callee's personal room
      callNamespace.to(calleeId).emit('incoming_call', {
        callId,
        callType: call.callType,
        initiatorId: socket.userId,
        initiatorName: initiatorName,
      });

      // FCM push only if the callee is offline
      if (!(await isUserOnline(connectedUsers, calleeId))) {
        try {
          const calleeUser = await User.findById(calleeId).select('_id').lean();
          if (calleeUser) {
            await sendCallNotificationToUser(calleeUser, {
              callId,
              callType: String(call.callType),
              initiatorId: socket.userId,
              initiatorName: initiatorName,
            });
          }
        } catch (fcmErr) {
          logger.error(`[FCM] Call invite failed for ${calleeId}: ${fcmErr.message}`);
        }
      } else {
        logger.info(`Callee ${calleeId} is online — skipping FCM push`);
      }
    }
  } catch (err) {
    logger.error(`initiateCall socket error: ${err.message}`);
    socket.emit('call_error', { error: err.message });
  }
};

module.exports = {
  isUserOnline,
  trackUser,
  untrackUser,
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
};
