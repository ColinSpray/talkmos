const mongoose = require('mongoose');
const Chat = require('../../../models/Chat');

const getCommunities = async ({ category, userId } = {}) => {
  const pipeline = [
    {
      $match: {
        chatType: 'community',
        deletedAt: null,
      },
    },
    {
      $lookup: {
        from: 'spaces',
        localField: 'spaceId',
        foreignField: '_id',
        as: 'space',
      },
    },
    { $unwind: { path: '$space', preserveNullAndEmptyArrays: true } },
  ];

  if (category) {
    pipeline.push({ $match: { 'space.category': category } });
  }

  pipeline.push(
    // Member count
    {
      $lookup: {
        from: 'chatmembers',
        let: { chatId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$chatId', '$$chatId'] },
                  { $eq: ['$isRemoved', false] },
                ],
              },
            },
          },
          { $count: 'count' },
        ],
        as: 'memberStats',
      },
    },
    // Is the requesting user a member?
    {
      $lookup: {
        from: 'chatmembers',
        let: { chatId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$chatId', '$$chatId'] },
                  {
                    $eq: [
                      '$userId',
                      userId ? new mongoose.Types.ObjectId(String(userId)) : null,
                    ],
                  },
                  { $eq: ['$isRemoved', false] },
                ],
              },
            },
          },
        ],
        as: 'myMembership',
      },
    },
    // Last message in this community
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
      $addFields: {
        name: '$space.name',
        description: '$space.description',
        imageUrl: '$space.imageUrl',
        isVerified: { $ifNull: ['$space.isVerified', false] },
        category: '$space.category',
        owner: '$space.owner',
        createdBy: '$space.createdBy',
        memberCount: {
          $ifNull: [{ $arrayElemAt: ['$memberStats.count', 0] }, 0],
        },
        isMember: { $gt: [{ $size: '$myMembership' }, 0] },
        lastMessage: { $ifNull: ['$lastMessageDoc', '$$REMOVE'] },
        lastActivityAt: { $ifNull: ['$lastMessageDoc.createdAt', '$createdAt'] },
      },
    },
    {
      $project: {
        space: 0,
        spaceId: 0,
        memberStats: 0,
        myMembership: 0,
        lastMessageDoc: 0,
        sender: 0,
        receiver: 0,
        activeCall: 0,
        __v: 0,
        deletedAt: 0
      },
    },
    { $sort: { lastActivityAt: -1 } }
  );

  return Chat.aggregate(pipeline);
};

module.exports = getCommunities ;
