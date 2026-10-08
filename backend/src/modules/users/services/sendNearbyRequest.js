const User = require('../../../models/User');
const FriendRequest = require('../../../models/FriendRequest');
const Notification = require('../../../models/Notification');
const { hasSeenPeer } = require('./nearbyPeers');

const MAX_MESSAGE_LENGTH = 200;

const fail = (status, message) => {
  const err = new Error(message);
  err.status = status;
  throw err;
};

const sendNearbyRequest = async ({ senderId, receiverId, message }) => {
  if (!receiverId) fail(400, 'receiverId is required');
  if (String(senderId) === String(receiverId)) fail(400, 'You cannot send a request to yourself');

  const text = String(message || '').trim();
  if (!text) fail(400, 'A message is required');
  if (text.length > MAX_MESSAGE_LENGTH) fail(400, `Message must be ${MAX_MESSAGE_LENGTH} characters or fewer`);

  if (!(await hasSeenPeer(senderId, receiverId))) {
    fail(403, 'That person is no longer nearby');
  }

  const receiver = await User.findById(receiverId).select('_id name nearbyEnabled isBlocked').lean();
  if (!receiver) fail(404, 'User not found');
  if (!receiver.nearbyEnabled) fail(403, 'That person is no longer nearby');

  const blocked = await User.exists({
    $or: [
      { _id: senderId, isBlocked: receiverId },
      { _id: receiverId, isBlocked: senderId },
    ],
  });
  if (blocked) fail(403, 'You cannot send a request to this user');

  const existing = await FriendRequest.findOne({
    $or: [
      { sender: senderId, receiver: receiverId },
      { sender: receiverId, receiver: senderId },
    ],
  })
    .select('status')
    .lean();

  if (existing) {
    if (existing.status === 'accepted') fail(400, 'You are already connected');
    if (existing.status === 'pending') fail(400, 'A request is already pending');
    fail(403, 'You cannot send another request to this user');
  }

  const request = await FriendRequest.create({
    sender: senderId,
    receiver: receiverId,
    status: 'pending',
    source: 'nearby',
    message: text,
  });

  const sender = await User.findById(senderId).select('_id name username avatarUrl').lean();

  await Notification.create({
    userId: receiverId,
    type: 'friend_request',
    title: 'New nearby request',
    body: `${sender?.name || 'Someone'} nearby wants to connect`,
    metadata: { friendRequestId: request._id, senderId, source: 'nearby' },
  });

  return { _id: request._id, status: request.status, createdAt: request.createdAt, sender };
};

module.exports = sendNearbyRequest;
