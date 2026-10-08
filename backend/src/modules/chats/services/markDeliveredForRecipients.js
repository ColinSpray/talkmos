const Message = require('../../../models/Message');
const UserChatPreference = require('../../../models/UserChatPreference');

const markDeliveredForRecipients = async ({ messageId, chatId, recipientIds = [] }) => {
  if (!messageId || !chatId || recipientIds.length === 0) return;

  const ids = [...new Set(recipientIds.map(String))];

  await Promise.all([
    // Conditional, so a message already marked read is not walked back to
    // delivered by a straggling acknowledgement.
    Message.updateOne({ _id: messageId, status: 'sent' }, { $set: { status: 'delivered' } }).exec(),
    UserChatPreference.bulkWrite(
      ids.map((userId) => ({
        updateOne: {
          filter: { userId, chatId },
          update: { $set: { lastDeliveredMessage: messageId } },
          upsert: true,
        },
      })),
      { ordered: false }
    ),
  ]);
};

module.exports = markDeliveredForRecipients;
