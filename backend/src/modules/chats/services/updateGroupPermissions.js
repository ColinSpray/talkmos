const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const { assertCanManage } = require('./helpers');

const ALLOWED = ['everyone', 'admins'];
const KEYS = ['sendMessages', 'editInfo', 'addMembers'];

const updateGroupPermissions = async ({ chatId, actorId, permissions = {} }) => {
  const updates = {};
  for (const key of KEYS) {
    const value = permissions[key];
    if (value === undefined) continue;
    if (!ALLOWED.includes(value)) {
      const err = new Error(`Invalid value for ${key}`);
      err.statusCode = 400;
      throw err;
    }
    updates[`permissions.${key}`] = value;
  }

  const [chat, membership] = await Promise.all([
    Chat.findById(chatId).select('chatType deletedAt').lean(),
    ChatMember.findOne({ chatId, userId: actorId, isRemoved: false }).select('role').lean(),
  ]);

  if (!chat || chat.deletedAt) {
    const err = new Error('Chat not found');
    err.statusCode = 404;
    throw err;
  }
  if (chat.chatType === 'direct') {
    const err = new Error('Direct chats have no permissions');
    err.statusCode = 400;
    throw err;
  }
  if (!membership) {
    const err = new Error('Not a member of this chat');
    err.statusCode = 403;
    throw err;
  }
  assertCanManage(membership);

  const updated = await Chat.findByIdAndUpdate(chatId, { $set: updates }, { new: true })
    .select('permissions')
    .lean();
  return updated.permissions;
};

module.exports = updateGroupPermissions;
