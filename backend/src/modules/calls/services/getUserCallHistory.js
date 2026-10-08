const CallParticipant = require('../../../models/CallParticipant');
const { attachParticipants } = require('./helpers');

const getUserCallHistory = async ({ userId, limit = 50 }) => {
  const records = await CallParticipant.find({ userId })
    .sort({ createdAt: -1 })
    .limit(Math.min(limit, 100))
    .populate({ path: 'callId', populate: { path: 'initiatedBy', select: 'name avatarUrl' } })
    .lean();

  const withCall = records.filter((r) => r.callId);
  const calls = await attachParticipants(withCall.map((r) => r.callId));

  return withCall.map((r, i) => ({
    call: calls[i],
    myStatus: r.status,
    joinedAt: r.joinedAt,
    leftAt: r.leftAt,
  }));
};

module.exports = getUserCallHistory;
