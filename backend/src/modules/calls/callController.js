const callService = require('./services');
const logger = require('../../utils/logger');
const { sendCallNotificationToUser } = require('../../services/fcmService');
const User = require('../../models/User');
const presence = require('../../services/presenceService');
const { emitCallEnded, emitCallDeclined } = require('../../services/callEvents');

const handleError = (res, error) => {
  logger.error(error);
  const statusCode = error.statusCode || 500;
  return res.status(statusCode).json({ success: false, message: error.message });
};

// Emits a lifecycle event to everyone in a call's signaling room (keyed by callId).
// Clients join this room via socket event `join_call_room` after REST /join succeeds.
const emitCallEvent = (req, callId, event, payload) => {
  const io = req.app.get('io');
  if (io) {
    io.of('/ws/call').to(String(callId)).emit(event, payload);
  }
};

// Emit directly to a user's personal room (they join it automatically on socket connect).
const emitToUser = (req, userId, event, payload) => {
  const io = req.app.get('io');
  if (io) {
    io.of('/ws/call').to(String(userId)).emit(event, payload);
  }
};

const callEnded = (req, callId, status, actorUserId) =>
  emitCallEnded(req.app.get('io'), { callId: String(callId), status, actorUserId });

const initiateCall = async (req, res) => {
  try {
    const callerId = req.user.id;
    const { chatId, callType, calleeName } = req.body;

    const { call, participants } = await callService.initiateCall({ chatId, callerId, callType });

    // Notify the callee via their personal socket room (immediate if connected).
    // participants[].userId is populated, so it has to be unwrapped before comparing.
    const callee = participants.find(
      (p) => String(p.userId._id || p.userId) !== String(callerId)
    );
    if (callee) {
      const calleeId = String(callee.userId._id || callee.userId);

      emitToUser(req, calleeId, 'incoming_call', {
        callId: String(call._id),
        callType: call.callType,
        initiatorId: String(callerId),
        initiatorName: calleeName || 'Someone',
      });

      // Only send FCM push if the callee is NOT online on the call namespace.
      // This mirrors the chat socket pattern: socket delivery if online, FCM fallback if offline.
      const calleeIsOnline = await presence.isOnline('call', calleeId);

      if (!calleeIsOnline) {
        try {
          const calleeUser = await User.findById(callee.userId).select('_id').lean();
          if (calleeUser) {
            await sendCallNotificationToUser(calleeUser, {
              callId: String(call._id),
              callType: String(call.callType),
              initiatorId: String(callerId),
              initiatorName: calleeName || 'Someone',
            });
          }
        } catch (fcmErr) {
          logger.error(`[FCM] Call notification failed in initiateCall: ${fcmErr.message}`);
        }
      } else {
        logger.info(`[Call] Callee ${calleeId} is online — skipping FCM push`);
      }
    }

    return res.status(201).json({ success: true, data: { call, participants } });
  } catch (error) {
    return handleError(res, error);
  }
};

const joinCall = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // callId

    const { call, participant } = await callService.joinCall({ callId: id, userId });

    // Broadcast to all peers already in the call's signaling room
    emitCallEvent(req, String(call._id), 'call_participant_joined', { callId: String(call._id), userId: String(userId), participant });

    return res.json({ success: true, data: { call, participant } });
  } catch (error) {
    return handleError(res, error);
  }
};

const declineCall = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // callId

    const { call, participant, endedNow } = await callService.declineCall({ callId: id, userId });

    await emitCallDeclined(req.app.get('io'), { callId: String(call._id), userId });
    if (endedNow) await callEnded(req, call._id, call.status, userId);

    return res.json({ success: true, data: { call, participant } });
  } catch (error) {
    return handleError(res, error);
  }
};

const leaveCall = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // callId

    const { call, participant, endedNow } = await callService.leaveCall({ callId: id, userId });

    emitCallEvent(req, String(call._id), 'call_participant_left', { callId: String(call._id), userId: String(userId), participant });
    if (endedNow) await callEnded(req, call._id, call.status, userId);

    return res.json({ success: true, data: { call, participant } });
  } catch (error) {
    return handleError(res, error);
  }
};

const endCall = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // callId
    const { status } = req.body; // optional: 'failed' to report a technical failure

    const { call, endedNow } = await callService.endCall({ callId: id, userId, status });

    if (endedNow) await callEnded(req, call._id, call.status, userId);

    return res.json({ success: true, data: call });
  } catch (error) {
    return handleError(res, error);
  }
};

const addParticipants = async (req, res) => {
  try {
    const actorId = req.user.id;
    const { id } = req.params; // callId
    const { userIds } = req.body;

    const participants = await callService.addParticipants({ callId: id, actorId, userIds });

    emitCallEvent(req, String(id), 'call_participants_added', { callId: String(id), participants });

    return res.status(201).json({ success: true, data: participants });
  } catch (error) {
    return handleError(res, error);
  }
};

const getCallById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const call = await callService.getCallById(id, userId);
    return res.json({ success: true, data: call });
  } catch (error) {
    return handleError(res, error);
  }
};

const getChatCallHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { chatId } = req.params;
    const { limit } = req.query;

    const calls = await callService.getChatCallHistory({ chatId, userId, limit });
    return res.json({ success: true, data: calls });
  } catch (error) {
    return handleError(res, error);
  }
};

const getMyCallHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit } = req.query;

    const history = await callService.getUserCallHistory({ userId, limit });
    return res.json({ success: true, data: history });
  } catch (error) {
    return handleError(res, error);
  }
};

module.exports = {
  initiateCall,
  joinCall,
  declineCall,
  leaveCall,
  endCall,
  addParticipants,
  getCallById,
  getChatCallHistory,
  getMyCallHistory,
  emitCallEvent,
  emitToUser,
};
