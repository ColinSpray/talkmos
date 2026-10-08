const ChatMember = require('../../../models/ChatMember');
const { assertMembership, assertCanManage } = require('./helpers');

const removeMember = async ({ chatId, actorId, targetUserId }) => {
  const actorMembership = await assertMembership(chatId, actorId);
  const targetMembership = await ChatMember.findOne({ chatId, userId: targetUserId, isRemoved: false });
  if (!targetMembership) throw new Error('Member not found in this chat');

  if (String(actorId) !== String(targetUserId)) {
    assertCanManage(actorMembership);
    if (targetMembership.role === 'owner') {
      const err = new Error('The chat owner cannot be removed');
      err.statusCode = 403;
      throw err;
    }
  }

  targetMembership.isRemoved = true;
  targetMembership.leftAt = new Date();
  targetMembership.canSendMessages = false;
  await targetMembership.save();

  return { success: true };
};

module.exports = removeMember;
