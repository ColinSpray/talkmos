const CallParticipant = require('../../../models/CallParticipant');
const finalizeCall = require('./finalizeCall');
const { getCallOr404, assertChatMembership, TERMINAL_STATUSES } = require('./helpers');

const endCall = async ({ callId, userId, status = 'ended' }) => {
  const call = await getCallOr404(callId);
  if (TERMINAL_STATUSES.includes(call.status)) return { call, endedNow: false };

  await assertChatMembership(call.chatId, userId);
  await finalizeCall(call, { status, endedBy: userId });

  await CallParticipant.updateMany(
    { callId: call._id, status: 'joined' },
    { $set: { status: 'left', leftAt: new Date() } }
  );

  return { call, endedNow: true };
};

module.exports = endCall;
