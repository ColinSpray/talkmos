const CallParticipant = require('../../../models/CallParticipant');
const finalizeCall = require('./finalizeCall');
const { getCallOr404 } = require('./helpers');

const declineCall = async ({ callId, userId }) => {
  const call = await getCallOr404(callId);

  const participant = await CallParticipant.findOne({ callId, userId });
  if (!participant) throw new Error('You were not invited to this call');

  participant.status = 'declined';
  await participant.save();

  const endedNow = !call.isGroupCall && call.status === 'ringing';
  if (endedNow) {
    await finalizeCall(call, { status: 'declined', endedBy: userId });
  }

  return { call, participant, endedNow };
};

module.exports = declineCall;
