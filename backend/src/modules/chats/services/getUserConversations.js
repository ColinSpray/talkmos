const mongoose = require('mongoose');
const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');

const DEFAULT_LIMIT = 0; // 0 = no limit

const getUserConversations = async (
  userId,
  { includeArchived = true, archivedOnly = false, limit = DEFAULT_LIMIT, before = null } = {}
) => {
  const uid = new mongoose.Types.ObjectId(String(userId));

  const memberChatIds = await ChatMember.find({ userId: uid, isRemoved: false })
    .distinct('chatId');

  const pipeline = [
    // Narrow to this user's chats FIRST, on indexed fields, so everything
    // downstream operates on their conversations rather than the whole table.
    {
      $match: {
        deletedAt: null,
        $or: [
          { chatType: 'direct', sender: uid },
          { chatType: 'direct', receiver: uid },
          { chatType: 'group', _id: { $in: memberChatIds } },
        ],
      },
    },
  ];

  if (before) {
    pipeline.push({ $match: { lastMessageAt: { $lt: new Date(before) } } });
  }

  pipeline.push(
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
          { $project: { isPinned: 1, isMuted: 1, isArchived: 1, hiddenAt: 1, lastReadAt: 1 } },
        ],
        as: 'preference',
      },
    },
    { $unwind: { path: '$preference', preserveNullAndEmptyArrays: true } },
    {
      $addFields: {
        isPinned: { $ifNull: ['$preference.isPinned', false] },
        isMuted: { $ifNull: ['$preference.isMuted', false] },
        isArchived: { $ifNull: ['$preference.isArchived', false] },
        hiddenAt: { $ifNull: ['$preference.hiddenAt', null] },
        lastReadAt: { $ifNull: ['$preference.lastReadAt', new Date(0)] },
        lastActivityAt: { $ifNull: ['$lastMessageAt', '$createdAt'] },
      },
    }
  );

  // A "deleted" chat stays hidden from the list until a newer message
  // arrives — same semantics as WhatsApp's delete-chat.
  pipeline.push({
    $match: {
      $expr: {
        $or: [
          { $eq: ['$hiddenAt', null] },
          { $gt: ['$lastActivityAt', '$hiddenAt'] },
        ],
      },
    },
  });

  if (archivedOnly) {
    pipeline.push({ $match: { isArchived: true } });
  } else if (!includeArchived) {
    pipeline.push({ $match: { isArchived: false } });
  }

  pipeline.push({ $sort: { isPinned: -1, lastActivityAt: -1 } });

  if (limit > 0) {
    pipeline.push({ $limit: limit });
  }

  pipeline.push(
    {
      $addFields: {
        otherUserId: { $cond: [{ $eq: ['$sender', uid] }, '$receiver', '$sender'] },
      },
    },
    {
      $lookup: {
        from: 'users',
        localField: 'otherUserId',
        foreignField: '_id',
        as: 'user',
        pipeline: [{ $project: { name: 1, avatarUrl: 1 } }],
      },
    },
    { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
    {
      $lookup: {
        from: 'spaces',
        localField: 'spaceId',
        foreignField: '_id',
        as: 'space',
        pipeline: [{ $project: { name: 1, imageUrl: 1 } }],
      },
    },
    { $unwind: { path: '$space', preserveNullAndEmptyArrays: true } },
    {
      $lookup: {
        from: 'chatmembers',
        localField: '_id',
        foreignField: 'chatId',
        pipeline: [
          { $match: { isRemoved: false } },
          {
            $lookup: {
              from: 'users',
              localField: 'userId',
              foreignField: '_id',
              as: 'user',
              pipeline: [{ $project: { name: 1, avatarUrl: 1 } }],
            },
          },
          { $unwind: '$user' },
          { $project: { _id: '$user._id', name: '$user.name', imageUrl: '$user.avatarUrl' } },
        ],
        as: 'groupMembers',
      },
    },
    // Newest message, for the list preview.
    {
      $lookup: {
        from: 'messages',
        let: { chatId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: { $eq: ['$chatId', '$$chatId'] },
              deletedForEveryone: { $ne: true },
            },
          },
          { $sort: { createdAt: -1 } },
          { $limit: 1 },
          {
            $lookup: {
              from: 'users',
              localField: 'senderId',
              foreignField: '_id',
              as: 'senderUser',
              pipeline: [{ $project: { name: 1 } }],
            },
          },
          { $unwind: { path: '$senderUser', preserveNullAndEmptyArrays: true } },
          {
            $project: {
              _id: 1,
              chatId: 1,
              senderId: 1,
              senderName: '$senderUser.name',
              messageType: 1,
              content: 1,
              media: 1,
              mentions: 1,
              forwarded: 1,
              edited: 1,
              status: 1,
              isPinned: 1,
              deletedForEveryone: 1,
              deletedForMe: 1,
              createdAt: 1,
              updatedAt: 1,
            },
          },
        ],
        as: 'lastMessageDoc',
      },
    },
    { $unwind: { path: '$lastMessageDoc', preserveNullAndEmptyArrays: true } },
    {
      $lookup: {
        from: 'messages',
        let: { chatId: '$_id', lastReadTime: '$lastReadAt' },
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
    {
      $addFields: {
        name: { $cond: [{ $eq: ['$chatType', 'group'] }, '$space.name', '$user.name'] },
        imageUrl: {
          $cond: [{ $eq: ['$chatType', 'group'] }, '$space.imageUrl', '$user.avatarUrl'],
        },
        members: {
          $cond: [
            { $eq: ['$chatType', 'group'] },
            '$groupMembers',
            {
              $cond: [
                { $ifNull: ['$user._id', false] },
                [
                  {
                    _id: '$user._id',
                    name: { $ifNull: ['$user.name', ''] },
                    imageUrl: { $ifNull: ['$user.avatarUrl', ''] },
                  },
                ],
                [],
              ],
            },
          ],
        },
        lastMessage: { $ifNull: ['$lastMessageDoc', '$$REMOVE'] },
        unreadCount: { $ifNull: ['$unreadAgg.count', 0] },
      },
    },
    {
      $project: {
        sender: 0,
        receiver: 0,
        otherUserId: 0,
        preference: 0,
        lastMessageDoc: 0,
        unreadAgg: 0,
        membership: 0,
        myMembership: 0,
        groupMembers: 0,
        user: 0,
        space: 0,
        lastReadAt: 0,
        __v: 0,
        updatedAt: 0,
        hiddenAt: 0,
      },
    }
  );

  return Chat.aggregate(pipeline);
};

module.exports = {
  getUserConversations,
};
