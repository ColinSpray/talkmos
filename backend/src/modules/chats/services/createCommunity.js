const mongoose = require('mongoose');
const Space = require('../../../models/Space');
const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const UserChatPreference = require('../../../models/UserChatPreference');

const createCommunity = async ({ userId, name, description, imageUrl, category }) => {
  if (!name || !name.trim()) {
    throw new Error('Community name is required');
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
              createdBy: userId,
              owner: userId,
              category: category || 'Tech',
            },
          ],
          { session }
        )
      )[0];

      chat = (
        await Chat.create([{ chatType: 'community', spaceId: space._id }], { session })
      )[0];

      await ChatMember.create(
        [{
          chatId: chat._id,
          userId: userId,
          role: 'owner',
        }],
        { session }
      );

      // Seed a default UserChatPreference for the creator so that
      // delivery/read cursor tracking is ready immediately.
      await UserChatPreference.create(
        [{
          userId: userId,
          chatId: chat._id,
          lastDeliveredMessage: null,
          lastReadMessage: null,
          isPinned: false,
          isMuted: false,
          isArchived: false,
        }],
        { session }
      );
    });

    return { space, generalChat: chat };
  } finally {
    session.endSession();
  }
};

module.exports = createCommunity;
