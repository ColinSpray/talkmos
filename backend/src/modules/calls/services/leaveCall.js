const CallParticipant = require('../../../models/CallParticipant');
const finalizeCall = require('./finalizeCall');
const { getCallOr404, TERMINAL_STATUSES } = require('./helpers');

const leaveCall = async ({ callId, userId }) => {
  const call = await getCallOr404(callId);

  const participant = await CallParticipant.findOne({ callId, userId, status: 'joined' });
  if (!participant) throw new Error('You are not currently in this call');

  participant.status = 'left';
  participant.leftAt = new Date();
  participant.disconnectedAt = null;
  await participant.save();

  const stillJoined = await CallParticipant.countDocuments({ callId, status: 'joined' });
  const pendingInvites = await CallParticipant.countDocuments({
    callId,
    status: { $in: ['invited', 'ringing'] },
  });

  const shouldEnd =
    stillJoined === 0 || (stillJoined === 1 && pendingInvites === 0);
  const endedNow = shouldEnd && !TERMINAL_STATUSES.includes(call.status);
  if (endedNow) {
    await finalizeCall(call, { status: 'ended', endedBy: userId });
  }

  return { call, participant, endedNow };
};

module.exports = leaveCall;
