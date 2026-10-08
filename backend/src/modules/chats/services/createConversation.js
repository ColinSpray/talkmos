const mongoose = require('mongoose');
const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const Space = require('../../../models/Space');
const UserChatPreference = require('../../../models/UserChatPreference');
const User = require('../../../models/User');
const FriendRequest = require('../../../models/FriendRequest');

const createConversation = async ({
  creatorId,
  spaceId = null,
  type,
  name,
  participantIds = [],
  imageUrl = '',
  description = '',
  category = 'Tech',
  skipFriendCheck = false,
}) => {
  if (!type || !['direct', 'group', 'community'].includes(type)) {
    throw new Error('Invalid chat type');
  }

  const uniqueIds = Array.from(new Set([String(creatorId), ...participantIds]));

  if (type === 'direct') {
    return createDirectChat({ creatorId, uniqueIds, skipFriendCheck });
  }

  return createSpaceBackedChat({
    chatType: type,
    creatorId,
    spaceId,
    name,
    uniqueIds,
    imageUrl,
    description,
    category,
    label: type === 'group' ? 'Group' : 'Community',
  });
};

async function createDirectChat({ creatorId, uniqueIds, skipFriendCheck = false }) {
  if (uniqueIds.length !== 2) {
    throw new Error('Direct chats must have exactly two members');
  }

  const [a, b] = uniqueIds.map(String).sort();
  const otherId = uniqueIds.find((id) => String(id) !== String(creatorId));

  const findExisting = () =>
    Chat.findOne({
      chatType: 'direct',
      $or: [
        { sender: a, receiver: b },
        { sender: b, receiver: a },
      ],
    });

  const existing = await findExisting();
  if (existing) {
    if (existing.deletedAt) {
      existing.deletedAt = null;
      await existing.save();
    }
    return { chat: existing, isNew: false };
  }

  if (!skipFriendCheck) {
    const [friendship, otherUser] = await Promise.all([
      FriendRequest.findOne({
        status: 'accepted',
        $or: [{ sender: creatorId, receiver: otherId }, { sender: otherId, receiver: creatorId }],
      }).lean(),
      User.findById(otherId).select('isPublic').lean(),
    ]);

    if (!friendship && !otherUser?.isPublic) {
      const err = new Error('You can only message friends or public accounts');
      err.statusCode = 403;
      throw err;
    }
  }

  try {
    const chat = await Chat.create({ chatType: 'direct', sender: a, receiver: b });
    return { chat, isNew: true };
  } catch (err) {
    // Two requests raced to create the same direct chat — reuse the winner.
    if (err && err.code === 11000) {
      const chat = await findExisting();
      if (chat) return { chat, isNew: false };
    }
    throw err;
  }
}

async function createSpaceBackedChat({
  chatType,
  creatorId,
  spaceId,
  name,
  uniqueIds,
  imageUrl,
  description,
  category,
  label,
}) {
  if (!name || !name.trim()) {
    throw new Error(`${label} name is required`);
  }
  if (uniqueIds.length < 2) {
    throw new Error(`A ${label.toLowerCase()} needs at least one other member besides you`);
  }

  if (spaceId) {
    const space = await Space.findById(spaceId);
    if (!space) {
      throw new Error('Space not found');
    }

    const requesterSpaceMembership = await SpaceMember.findOne({
      spaceId,
      userId: creatorId,
    });
    if (!requesterSpaceMembership) {
      throw new Error('You are not a member of this space');
    }

    let chat = await Chat.findOne({ spaceId: space._id, chatType });
    if (!chat) {
      chat = await Chat.create({ chatType, spaceId: space._id });
    }
    return { chat, space, isNew: false };
  }

  const session = await mongoose.startSession();
  try {
    let chat;
    let space;
    await session.withTransaction(async () => {
      space = (
        await Space.create(
          [
            {
              name: name.trim(),
              imageUrl: imageUrl || '',
              description: description || '',
              createdBy: creatorId,
              owner: creatorId,
              category,
            },
          ],
          { session }
        )
      )[0];

      chat = (
        await Chat.create([{ chatType, spaceId: space._id }], { session })
      )[0];

      await ChatMember.insertMany(
        uniqueIds.map((uId) => ({
          chatId: chat._id,
          userId: uId,
          role: String(uId) === String(creatorId) ? 'owner' : 'member',
        })),
        { session }
      );

      await UserChatPreference.insertMany(
        uniqueIds.map((uId) => ({
          userId: uId,
          chatId: chat._id,
          lastDeliveredMessage: null,
          lastReadMessage: null,
          isPinned: false,
          isMuted: false,
          isArchived: false,
        })),
        { session, ordered: false }
      );

    });

    return { chat, space, isNew: true };
  } finally {
    session.endSession();
  }
}

module.exports = createConversation;
