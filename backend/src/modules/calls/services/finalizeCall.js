const Call = require('../../../models/Call');
const CallParticipant = require('../../../models/CallParticipant');
const Chat = require('../../../models/Chat');

const finalizeCall = async (call, { status = 'ended', endedBy = null } = {}) => {
  const now = new Date();

  // Doubles as the answer to "did this connect at all" and "when" — a call
  // whose only participant is the caller was never answered.
  const firstOtherJoin = await CallParticipant.findOne({
    callId: call._id,
    userId: { $ne: call.initiatedBy },
    status: { $in: ['joined', 'left'] },
  })
    .sort({ joinedAt: 1 })
    .select('joinedAt')
    .lean();

  let finalStatus = status;
  if (status === 'ended' && !firstOtherJoin) finalStatus = 'missed';

  // Falls back to the participant's own timestamp for a call that connected
  // before this field existed.
  const connectedAt = call.connectedAt || firstOtherJoin?.joinedAt || null;

  call.status = finalStatus;
  call.endedAt = now;
  call.endedBy = endedBy;
  call.connectedAt = connectedAt;
  // Talk time, not ring time — a call nobody answered lasted zero seconds.
  call.duration = connectedAt
    ? Math.max(0, Math.round((now - connectedAt) / 1000))
    : 0;
  await call.save();

  await CallParticipant.updateMany(
    { callId: call._id, status: { $in: ['invited', 'ringing'] } },
    { $set: { status: 'missed' } }
  );

  await Chat.updateOne({ _id: call.chatId, activeCall: call._id }, { $set: { activeCall: null } });

  return call;
};

module.exports = finalizeCall;
