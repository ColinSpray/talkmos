const mongoose = require('mongoose');
const Chat = require('../../../models/Chat');
const Message = require('../../../models/Message');
const User = require('../../../models/User');
const UserChatPreference = require('../../../models/UserChatPreference');
const { assertMembership } = require('./helpers');

const markMessagesRead = async ({ chatId, readerId, senderId = null }) => {
  if (!chatId || !mongoose.Types.ObjectId.isValid(chatId)) {
    return { success: false, sentReadReceipt: false };
  }

  const [membership, chat, reader, latestMessage] = await Promise.all([
    assertMembership(chatId, readerId),
    Chat.findById(chatId).select('chatType').lean(),
    User.findById(readerId).select('readReceiptsEnabled').lean(),
    Message.findOne({ chatId }).sort({ createdAt: -1 }).select('_id createdAt').lean(),
  ]);

  const sendReadReceipt =
    chat?.chatType !== 'direct' || reader?.readReceiptsEnabled !== false;

  const writes = [];

  if (sendReadReceipt) {
    writes.push(
      Message.updateMany(
        {
          chatId,
          status: { $ne: 'read' },
          ...(senderId ? { senderId } : { senderId: { $ne: readerId } }),
        },
        { $set: { status: 'read' } }
      ).exec()
    );
  }

  writes.push(
    UserChatPreference.updateOne(
      { userId: readerId, chatId },
      {
        $set: {
          chatMemberId: membership._id,
          ...(latestMessage
            ? {
                lastReadMessage: latestMessage._id,
                lastDeliveredMessage: latestMessage._id,
                // Denormalized so the unread pipelines can read the cursor
                // without joining back into messages for this one timestamp.
                lastReadAt: latestMessage.createdAt,
              }
            : {}),
        },
      },
      { upsert: true }
    ).exec()
  );

  await Promise.all(writes);

  return { success: true, sentReadReceipt: sendReadReceipt };
};

module.exports = markMessagesRead;
