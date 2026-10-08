const Message = require('../../../models/Message');
const { assertMembership } = require('./helpers');

const deleteMessage = async ({ messageId, userId, forEveryone = false }) => {
  const message = await Message.findById(messageId);
  if (!message) {
    throw new Error('Message not found');
  }
  const members = await assertMembership(message.chatId, userId);

  if (forEveryone) {
    if (String(message.senderId) !== String(userId)) {
      const err = new Error('You can only delete your own messages for everyone');
      err.statusCode = 403;
      throw err;
    }
    message.deletedAt = new Date();
    message.deletedForEveryone = true;
    message.content = '';
    message.media = { url: '', thumbnail: '', fileName: '', mimeType: '', size: 0, duration: 0 };
  } else {
    const alreadyDeleted = message.deletedForMe.some((id) => String(id) === String(userId));
    if (!alreadyDeleted) {
      message.deletedForMe.push(userId);
    }
  }

  await message.save();
  return {message, members};
};

module.exports = deleteMessage;
