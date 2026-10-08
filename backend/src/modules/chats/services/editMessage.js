const Message = require('../../../models/Message');
const { assertMembership } = require('./helpers');
const { assertContentLength } = require('../messageLimits');
const { keyIdOf } = require('../ciphertextEnvelope');

const editMessage = async ({ messageId, userId, content }) => {
  const message = await Message.findById(messageId);
  if (!message) {
    const err = new Error('Message not found');
    err.statusCode = 404;
    throw err;
  }

  await assertMembership(message.chatId, userId);

  if (String(message.senderId) !== String(userId)) {
    const err = new Error('You can only edit your own messages');
    err.statusCode = 403;
    throw err;
  }
  if (message.deletedForEveryone) {
    const err = new Error('Cannot edit a deleted message');
    err.statusCode = 400;
    throw err;
  }
  if (message.messageType !== 'text') {
    const err = new Error('Only text messages can be edited');
    err.statusCode = 400;
    throw err;
  }

  const trimmed = (content || '').trim();
  assertContentLength(trimmed);
  if (!trimmed) {
    const err = new Error('Message content cannot be empty');
    err.statusCode = 400;
    throw err;
  }

  message.content = trimmed;
  // Re-read rather than kept: an edit is a fresh encryption, under whatever
  // key the editing client holds now.
  message.keyId = keyIdOf(trimmed);
  message.edited = true;
  message.editedAt = new Date();
  await message.save();

  return message;
};

module.exports = editMessage;
