const mongoose = require('mongoose');
const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');

// Computes unread_chats and new_group_messages directly in the DB,
// without loading/looping over full conversation documents in JS.
const getUnreadCounts = async (userId) => {
  const uid = new mongoose.Types.ObjectId(String(userId));

  const memberChatIds = await ChatMember.find({ userId: uid, isRemoved: false })
    .distinct('chatId');

  const pipeline = [
    // 1. This user's chats, on indexed fields, before anything else runs
    {
      $match: {
        deletedAt: null,
        $or: [
          { chatType: 'direct', sender: uid },
          { chatType: 'direct', receiver: uid },
          { _id: { $in: memberChatIds } },
        ],
      },
    },

    // 2. Personal preferences — for isArchived, and for the read cursor
    {
      $lookup: {
        from: 'userchatpreferences',
        let: { chatId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: { $and: [{ $eq: ['$chatId', '$$chatId'] }, { $eq: ['$userId', uid] }] },
            },
          },
          { $project: { isArchived: 1, lastReadAt: 1 } },
        ],
        as: 'preference',
      },
    },
    { $unwind: { path: '$preference', preserveNullAndEmptyArrays: true } },

    // 3. Skip archived chats — drops rows before the per-chat count below
    {
      $match: {
        $expr: { $ne: [{ $ifNull: ['$preference.isArchived', false] }, true] },
      },
    },

    {
      $lookup: {
        from: 'messages',
        let: {
          chatId: '$_id',
          lastReadTime: { $ifNull: ['$preference.lastReadAt', new Date(0)] },
        },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$chatId', '$$chatId'] },
                  { $gt: ['$createdAt', '$$lastReadTime'] },
                  { $ne: ['$senderId', uid] },
                  { $eq: ['$deletedAt', null] },
                ],
              },
            },
          },
          { $count: 'count' },
        ],
        as: 'unreadAgg',
      },
    },
    { $unwind: { path: '$unreadAgg', preserveNullAndEmptyArrays: true } },
    { $addFields: { unread: { $ifNull: ['$unreadAgg.count', 0] } } },

    // 5. Sum everything up in the DB — no JS-side looping
    {
      $group: {
        _id: null,
        unreadChats: { $sum: '$unread' },
        unreadGroupMsgs: {
          $sum: {
            $cond: [{ $ne: ['$chatType', 'direct'] }, '$unread', 0],
          },
        },
      },
    },
  ];

  const [result] = await Chat.aggregate(pipeline);

  return {
    unreadChats: result?.unreadChats || 0,
    unreadGroupMsgs: result?.unreadGroupMsgs || 0,
  };
};

module.exports = getUnreadCounts;
