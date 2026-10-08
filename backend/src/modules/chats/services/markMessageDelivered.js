const Message = require('../../../models/Message');
const UserChatPreference = require('../../../models/UserChatPreference');

const markMessageDelivered = async ({ messageId, receiverId }) => {
  const message = await Message.findOneAndUpdate(
    { _id: messageId, senderId: { $ne: receiverId }, status: 'sent' },
    { $set: { status: 'delivered' } },
    { new: true }
  );

  // Nothing matched: already delivered/read, sent by this user, or gone.
  // Either way there is no delivery to record and nothing to tell the sender.
  if (!message) return null;

  await UserChatPreference.updateOne(
    { userId: receiverId, chatId: message.chatId },
    { $set: { lastDeliveredMessage: message._id } },
    { upsert: true }
  );

  return message;
};

module.exports = markMessageDelivered;
