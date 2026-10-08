const UserChatPreference = require('../../../models/UserChatPreference');
const Message = require('../../../models/Message');
const { assertMembership } = require('./helpers');

const updateMemberPreferences = async ({ chatId, userId, isPinned, isMuted, isArchived, hidden }) => {
  const membership = await assertMembership(chatId, userId);

  const update = { chatMemberId: membership._id };
  if (typeof isPinned === 'boolean') update.isPinned = isPinned;
  if (typeof isMuted === 'boolean') update.isMuted = isMuted;
  if (typeof isArchived === 'boolean') update.isArchived = isArchived;
  if (typeof hidden === 'boolean') update.hiddenAt = hidden ? new Date() : null;

  const preference = await UserChatPreference.findOneAndUpdate(
    { chatId, userId },
    update,
    { upsert: true, new: true }
  );

  if (hidden === true) {
    await Message.updateMany(
      { chatId, deletedForMe: { $ne: userId } },
      { $addToSet: { deletedForMe: userId } }
    );
  }

  return preference;
};

module.exports = updateMemberPreferences;
