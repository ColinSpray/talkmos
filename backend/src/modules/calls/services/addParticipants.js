const CallParticipant = require('../../../models/CallParticipant');
const { getCallOr404, assertChatMembership, TERMINAL_STATUSES } = require('./helpers');

const addParticipants = async ({ callId, actorId, userIds = [] }) => {
  const call = await getCallOr404(callId);
  // Both of these are the caller asking for something the call cannot do, not
  // the server failing. Without a statusCode they surface as 500s and are
  // indistinguishable from a real fault in monitoring.
  if (!call.isGroupCall) {
    const err = new Error('Cannot add participants to a 1:1 call');
    err.statusCode = 400;
    throw err;
  }
  if (TERMINAL_STATUSES.includes(call.status)) {
    const err = new Error('This call has already ended');
    err.statusCode = 400;
    throw err;
  }

  await assertChatMembership(call.chatId, actorId);

  const results = [];
  for (const uId of Array.from(new Set(userIds.map(String)))) {
    await assertChatMembership(call.chatId, uId);

    const existing = await CallParticipant.findOne({ callId, userId: uId });
    if (existing) {
      if (['invited', 'missed', 'declined'].includes(existing.status)) {
        existing.status = 'ringing';
        await existing.save();
      }
      results.push(existing);
      continue;
    }

    results.push(await CallParticipant.create({ callId, userId: uId, status: 'ringing' }));
  }

  return results;
};

module.exports = addParticipants;
