const removeMember = require('./removeMember');

const leaveConversation = async ({ chatId, userId }) => {
  return removeMember({ chatId, actorId: userId, targetUserId: userId });
};

module.exports = leaveConversation;
