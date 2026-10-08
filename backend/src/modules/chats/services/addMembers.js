const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const { assertMembership, assertPermission } = require('./helpers');

const addMembers = async ({ chatId, actorId, userIds = [] }) => {
  const chat = await Chat.findById(chatId);
  if (!chat || chat.isDeleted) throw new Error('Chat not found');
  if (chat.chatType === 'direct') throw new Error('Cannot add members to a direct chat');

  const actorMembership = await assertMembership(chatId, actorId);
  assertPermission(chat, actorMembership, 'addMembers');

  const results = [];
  for (const uId of Array.from(new Set(userIds.map(String)))) {
    const existing = await ChatMember.findOne({ chatId, userId: uId });
    if (existing) {
      if (existing.isRemoved) {
        existing.isRemoved = false;
        existing.leftAt = null;
        existing.joinedAt = new Date();
        await existing.save();
        results.push(existing);
      }
      continue;
    }
    const member = await ChatMember.create({ chatId, userId: uId, role: 'member' });
    results.push(member);
  }

  return results;
};

module.exports = addMembers;
