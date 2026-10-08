const Call = require('../../../models/Call');
const { assertChatMembership, attachParticipants } = require('./helpers');

const getChatCallHistory = async ({ chatId, userId, limit = 30 }) => {
  await assertChatMembership(chatId, userId);
  const calls = await Call.find({ chatId })
    .sort({ createdAt: -1 })
    .limit(Math.min(limit, 100))
    .populate('initiatedBy', 'name avatarUrl')
    .lean();

  return attachParticipants(calls);
};

module.exports = getChatCallHistory;
