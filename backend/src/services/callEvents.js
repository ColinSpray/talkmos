const logger = require('../utils/logger');
const CallParticipant = require('../models/CallParticipant');
const User = require('../models/User');
const presence = require('./presenceService');
const { sendCallEndedNotificationToUser } = require('./fcmService');

const CALL_NAMESPACE = '/ws/call';
const CALL_NS_PRESENCE = 'call';

const callNamespace = (io) => (io ? io.of(CALL_NAMESPACE) : null);

const participantIds = async (callId) => {
  const participants = await CallParticipant.find({ callId }).select('userId').lean();
  return participants
    .map((p) => String(p.userId?._id || p.userId || ''))
    .filter(Boolean);
};

// A participant may sit in the call's signaling room, in their own personal
// room, or both — and a peer still ringing is only in the latter. Emitting to
// each room separately delivers twice to anyone in both, so the rooms are
// unioned into a single broadcast: Socket.IO then delivers once per socket.
// The actor is excluded by personal room, which covers every device they have.
const broadcastToCall = async (io, callId, event, payload, { actorUserId = null } = {}) => {
  const nsp = callNamespace(io);
  if (!nsp) return [];

  const userIds = await participantIds(callId);

  let channel = nsp.to(String(callId));
  for (const uid of userIds) channel = channel.to(uid);
  if (actorUserId) channel = channel.except(String(actorUserId));
  channel.emit(event, payload);

  return userIds;
};

// Call this only when the call actually transitioned into a terminal status on
// this operation — the services report that as `endedNow`. Every teardown path
// (leave, end, decline, disconnect) can reach a terminal call, but only the one
// that caused the transition announces it.
const emitCallEnded = async (io, { callId, status, actorUserId = null }) => {
  const id = String(callId);
  try {
    const userIds = await broadcastToCall(
      io,
      id,
      'call_ended',
      { callId: id, status },
      { actorUserId }
    );

    for (const uid of userIds) {
      if (actorUserId && uid === String(actorUserId)) continue;
      try {
        if (await presence.isOnline(CALL_NS_PRESENCE, uid)) continue;
        const user = await User.findById(uid).select('_id').lean();
        if (user) await sendCallEndedNotificationToUser(user, { callId: id });
      } catch (fcmErr) {
        logger.error(`call_ended FCM fallback failed for ${uid}: ${fcmErr.message}`);
      }
    }
  } catch (err) {
    logger.error(`emitCallEnded error for call ${id}: ${err.message}`);
  }
};

const emitCallDeclined = async (io, { callId, userId }) => {
  const id = String(callId);
  try {
    await broadcastToCall(
      io,
      id,
      'call_declined',
      { callId: id, userId: String(userId) },
      { actorUserId: userId }
    );
  } catch (err) {
    logger.error(`emitCallDeclined error for call ${id}: ${err.message}`);
  }
};

// A participant's socket dropped and the call is being held open for them.
// Peers use it to show that someone is reconnecting rather than gone; the
// pairing event is either call_participant_joined (they came back) or
// call_participant_left (the grace period ran out).
const emitCallParticipantDisconnected = async (
  io,
  { callId, userId, reconnectWithinMs }
) => {
  const id = String(callId);
  try {
    await broadcastToCall(
      io,
      id,
      'call_participant_disconnected',
      { callId: id, userId: String(userId), reconnectWithinMs },
      { actorUserId: userId }
    );
  } catch (err) {
    logger.error(`emitCallParticipantDisconnected error for call ${id}: ${err.message}`);
  }
};

// The socket-bound path emits this itself; this one exists for the countdown,
// which finalizes a leave long after the socket that started it is gone.
const emitCallParticipantLeft = async (io, { callId, userId, status }) => {
  const id = String(callId);
  try {
    await broadcastToCall(
      io,
      id,
      'call_participant_left',
      { callId: id, userId: String(userId), status },
      { actorUserId: userId }
    );
  } catch (err) {
    logger.error(`emitCallParticipantLeft error for call ${id}: ${err.message}`);
  }
};

module.exports = {
  emitCallEnded,
  emitCallDeclined,
  emitCallParticipantDisconnected,
  emitCallParticipantLeft,
  broadcastToCall,
  CALL_NAMESPACE,
};
