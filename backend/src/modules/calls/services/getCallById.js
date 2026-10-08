const Call = require('../../../models/Call');
const CallParticipant = require('../../../models/CallParticipant');
const { assertChatMembership } = require('./helpers');

const getCallById = async (callId, userId) => {
  const call = await Call.findById(callId).lean();
  if (!call) {
    const err = new Error('Call not found');
    err.statusCode = 404;
    throw err;
  }

  await assertChatMembership(call.chatId, userId);

  const participants = await CallParticipant.find({ callId })
    .populate('userId', 'name avatarUrl')
    .lean();

  return { ...call, participants };
};

module.exports = getCallById;
