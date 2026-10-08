const Chat = require('../../../models/Chat');
const Space = require('../../../models/Space');
const { assertMembership, assertPermission } = require('./helpers');

const updateGroupInfo = async ({ chatId, actorId, name, image, description }) => {
  const chat = await Chat.findById(chatId);
  if (!chat || chat.isDeleted) throw new Error('Chat not found');
  if (chat.chatType === 'direct') throw new Error('Direct chats cannot be renamed');
  if (!chat.spaceId) throw new Error('This chat has no associated space to rename');

  const actorMembership = await assertMembership(chatId, actorId);
  assertPermission(chat, actorMembership, 'editInfo');

  const space = await Space.findById(chat.spaceId);
  if (!space) throw new Error('Space not found');

  if (typeof name === 'string' && name.trim()) space.name = name.trim();
  if (typeof image === 'string') space.imageUrl = image;
  if (typeof description === 'string') space.description = description.trim();
  await space.save();

  return { chat, space };
};

module.exports = updateGroupInfo;
