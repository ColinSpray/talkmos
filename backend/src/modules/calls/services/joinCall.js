const CallParticipant = require('../../../models/CallParticipant');
const { getCallOr404, assertChatMembership, TERMINAL_STATUSES } = require('./helpers');

const joinCall = async ({ callId, userId }) => {
  const call = await getCallOr404(callId);
  if (TERMINAL_STATUSES.includes(call.status)) {
    const err = new Error('This call has already ended');
    err.statusCode = 410;
    throw err;
  }

  let participant = await CallParticipant.findOne({ callId, userId });
  if (!participant) {
    await assertChatMembership(call.chatId, userId);
    participant = await CallParticipant.create({ callId, userId, status: 'ringing' });
  }

  // Rejoining is how a client that lost its socket comes back, so this is
  // what calls off the pending leave — including on the path where the
  // participant never stopped counting as joined.
  const wasDisconnected = Boolean(participant.disconnectedAt);
  participant.disconnectedAt = null;

  if (participant.status === 'joined') {
    if (wasDisconnected) await participant.save();
    return { call, participant };
  }

  participant.status = 'joined';
  participant.joinedAt = new Date();
  await participant.save();

  if (call.status === 'ringing') {
    call.status = 'ongoing';
    // The caller is already 'joined' from initiateCall, so reaching here means
    // somebody else has just picked up: the call is connected as of now.
    call.connectedAt = participant.joinedAt;
    await call.save();
  }

  return { call, participant };
};

module.exports = joinCall;
