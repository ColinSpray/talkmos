const User = require('../../models/User');
const FriendRequest = require('../../models/FriendRequest');
const Chat = require('../../models/Chat');
const Notification = require('../../models/Notification');
const createConversations = require('../chats/services/createConversation');
const { sendPushToUser } = require('../../services/fcmService');
const { areContacts, canViewProfilePhoto, isBlockedEitherWay } = require('./services/privacy');
const logger = require('../../utils/logger');
const userCache = require('../../services/userCache');
const setNearbyEnabledSvc = require('./services/setNearbyEnabled');
const nearbyHeartbeatSvc = require('./services/nearbyHeartbeat');
const sendNearbyRequestSvc = require('./services/sendNearbyRequest');
const nearbyPingSvc = require('./services/nearbyPing');

const emitToUser = (req, userId, event, payload) => {
  const io = req.app.get('io');
  if (io) io.of('/ws/chat').to(String(userId)).emit(event, payload);
};

const searchUsers = async (req, res) => {
  const { q } = req.query;

  // Escaped: the raw term would otherwise be compiled as a pattern, letting a
  // caller match every user with `.*` or hang the worker with a nested quantifier.
  const regex = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  const users = await User.find({
    _id: { $ne: req.user._id },
    role: 'user',
    $or: [{ name: regex }, { email: regex }, { phone: regex }, { username: regex }],
  })
    .select('_id name username email phone avatarUrl status isVerified isPublic profilePhotoVisibility')
    .limit(20)
    .lean();

  const data = await Promise.all(
    users.map(async ({ profilePhotoVisibility, ...user }) => ({
      ...user,
      isPublic: !!user.isPublic,
      avatarUrl: (await canViewProfilePhoto(req.user._id, user._id)) ? user.avatarUrl : '',
    }))
  );

  res.json({ success: true, data });
};

// Public profile lookup by id — for a chat deep link to resolve who it's
// pointing at before starting/opening the conversation.
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    if (await isBlockedEitherWay(req.user._id, id)) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const user = await User.findById(id)
      .select('_id name username avatarUrl bio isVerified isPublic profilePhotoVisibility')
      .lean();
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const { profilePhotoVisibility, ...rest } = user;
    const canSeePhoto = await canViewProfilePhoto(req.user._id, user._id);
    const isSelf = String(req.user._id) === String(user._id);
    const canSeeDetails =
      isSelf || !!user.isPublic || (await areContacts(req.user._id, user._id));

    return res.json({
      success: true,
      data: {
        ...rest,
        bio: canSeeDetails ? rest.bio : '',
        avatarUrl: canSeePhoto ? rest.avatarUrl : '',
      },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const sendFriendRequest = async (req, res) => {
  try {
    const senderId = req.user._id;
    const { receiverId } = req.body;

    if (String(senderId) === String(receiverId)) {
      return res.status(400).json({ success: false, message: 'You cannot send a friend request to yourself' });
    }

    const receiver = await User.findById(receiverId);
    if (!receiver) {
      return res.status(404).json({ success: false, message: 'Receiver user not found' });
    }

    const blocked = await User.exists({
      $or: [
        { _id: senderId, isBlocked: receiverId },
        { _id: receiverId, isBlocked: senderId },
      ],
    });
    if (blocked) {
      return res.status(403).json({ success: false, message: 'You cannot send a friend request to this user' });
    }

    const existingRequest = await FriendRequest.findOne({
      $or: [
        { sender: senderId, receiver: receiverId },
        { sender: receiverId, receiver: senderId },
      ],
    });

    let friendRequest;
    if (existingRequest) {
      if (existingRequest.status === 'accepted') {
        return res.status(400).json({ success: false, message: 'You are already friends' });
      }
      if (existingRequest.status === 'pending') {
        return res.status(400).json({ success: false, message: 'Friend request is already pending' });
      }
      existingRequest.sender = senderId;
      existingRequest.receiver = receiverId;
      existingRequest.status = 'pending';
      existingRequest.createdAt = Date.now();
      await existingRequest.save();
      friendRequest = existingRequest;
    } else {
      friendRequest = await FriendRequest.create({ sender: senderId, receiver: receiverId, status: 'pending' });
    }

    const sender = await User.findById(senderId).select('_id name username email avatarUrl status');
    const title = 'New Friend Request';
    const body = `${sender?.name || 'Someone'} sent you a friend request`;

    await Notification.create({
      userId: receiverId,
      type: 'friend_request',
      title,
      body,
      metadata: { friendRequestId: friendRequest._id, senderId },
    });

    // Push covers backgrounded/killed app states (regular notification
    // payload — the OS displays it directly regardless of app state).
    sendPushToUser(receiver, title, body, {
      type: 'friend_request',
      friendRequestId: String(friendRequest._id),
      senderId: String(senderId),
    });

    // Socket covers the case where the receiver has the app open right now,
    // so the Friends screen updates live without a manual pull-to-refresh.
    emitToUser(req, receiverId, 'friend_request_received', {
      _id: String(friendRequest._id),
      status: friendRequest.status,
      createdAt: friendRequest.createdAt,
      sender,
    });

    return res.status(existingRequest ? 200 : 201).json({ success: true, message: 'Friend request sent', data: friendRequest });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const getPendingRequests = async (req, res) => {
  try {
    const userId = req.user._id;
    const [incoming, outgoing] = await Promise.all([
      FriendRequest.find({ receiver: userId, status: 'pending' })
        .populate('sender', '_id name username email avatarUrl status isVerified')
        .lean(),
      FriendRequest.find({ sender: userId, status: 'pending' })
        .populate('receiver', '_id name username email avatarUrl status isVerified')
        .lean(),
    ]);

    return res.json({
      success: true,
      data: incoming,
      incoming,
      outgoing,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const updateFriendRequest = async (req, res) => {
  try {
    const userId = req.user._id;
    const { id } = req.params;
    const { status } = req.body;

    const request = await FriendRequest.findById(id);
    if (!request) {
      return res.status(404).json({ success: false, message: 'Friend request not found' });
    }

    if (String(request.receiver) !== String(userId)) {
      return res.status(403).json({ success: false, message: 'Not authorized to update this friend request' });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({ success: false, message: `Friend request already ${request.status}` });
    }

    request.status = status;

    if (status === 'accepted') {
      let chat = await Chat.findOne({
        chatType: 'direct',
        $or: [
          { sender: request.sender, receiver: request.receiver },
          { sender: request.receiver, receiver: request.sender },
        ],
      });
      if (!chat) {
        const result = await createConversations({ creatorId: userId, type: 'direct', participantIds: [request.sender], skipFriendCheck: true });
        chat = result.chat;
      }
      request.chatId = chat._id;
    }

    await request.save();

    const responder = await User.findById(userId).select('_id name username avatarUrl status');

    // Socket: notify the original sender live if they're online right now.
    emitToUser(req, request.sender, 'friend_request_updated', {
      _id: String(request._id),
      status: request.status,
      chatId: request.chatId ? String(request.chatId) : null,
      responder,
    });

    res.json({ success: true, message: `Friend request ${status}`, data: request });

    // Push & DB notification: process asynchronously after returning HTTP response to client
    if (status === 'accepted') {
      const title = 'Friend Request Accepted';
      const body = `${responder?.name || 'Someone'} accepted your friend request`;

      Notification.create({
        userId: request.sender,
        type: 'friend_request_accepted',
        title,
        body,
        metadata: { friendRequestId: request._id, responderId: userId },
      }).catch((err) => logger.warn(`[Notification] Error creating notification: ${err.message}`));

      User.findById(request.sender).select('_id').then((originalSender) => {
        if (originalSender) {
          sendPushToUser(originalSender, title, body, {
            type: 'friend_request_accepted',
            friendRequestId: String(request._id),
            responderId: String(userId),
          }).catch((err) => logger.warn(`[FCM] Error sending friend accepted notification: ${err.message}`));
        }
      }).catch((err) => logger.warn(`[User] Error fetching sender token: ${err.message}`));
    }
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const getFriends = async (req, res) => {
  try {
    const userId = req.user._id;
    const friendships = await FriendRequest.find({
      status: 'accepted',
      $or: [{ sender: userId }, { receiver: userId }],
    })
      .populate('sender', '_id name username email avatarUrl status isVerified')
      .populate('receiver', '_id name username email avatarUrl status isVerified')
      .lean();

    const friends = friendships.map((f) => {
      const friend = String(f.sender._id) === String(userId) ? f.receiver : f.sender;
      return { ...friend, chatId: f.chatId ? String(f.chatId) : null };
    });

    return res.json({ success: true, data: friends });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const userId = req.user._id;
    const { name, username, bio, location, language, avatarUrl, isPublic } = req.body;

    const updated = await User.findByIdAndUpdate(
      userId,
      { $set: { name, username, bio, location, language, avatarUrl, isPublic } },
      { new: true, runValidators: true }
    ).select('-password');
    await userCache.invalidateUser(userId);

    return res.json({ success: true, data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const blockUser = async (req, res) => {
  try {
    const userId = req.user._id;
    const { id: targetId } = req.params;

    if (String(userId) === String(targetId)) {
      return res.status(400).json({ success: false, message: 'You cannot block yourself' });
    }

    const target = await User.findById(targetId).select('_id');
    if (!target) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    await User.findByIdAndUpdate(userId, { $addToSet: { isBlocked: targetId } });
    await userCache.invalidateUser(userId);
    return res.json({ success: true, message: 'User blocked' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const unblockUser = async (req, res) => {
  try {
    const userId = req.user._id;
    const { id: targetId } = req.params;

    await User.findByIdAndUpdate(userId, { $pull: { isBlocked: targetId } });
    await userCache.invalidateUser(userId);
    return res.json({ success: true, message: 'User unblocked' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const getBlockedUsers = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .select('isBlocked')
      .populate('isBlocked', '_id name username email avatarUrl status isVerified')
      .lean();
    return res.json({ success: true, data: user?.isBlocked || [] });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const matchContactsSvc = require('./services/matchContacts');

const matchContacts = async (req, res) => {
  try {
    const { phones } = req.body;
    const matches = await matchContactsSvc({ userId: req.user.id, phones });
    return res.json({ success: true, data: matches });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Nearby services signal expected failures with err.status; anything without
// one is a real fault and stays a 500.
const nearbyHandler = (fn) => async (req, res) => {
  try {
    const data = await fn(req);
    return res.json({ success: true, data });
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ success: false, message: error.message });
    }
    logger.error(`[nearby] ${req.method} ${req.path}: ${error.message}`);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const setNearbySettings = nearbyHandler((req) =>
  setNearbyEnabledSvc(req.user._id, req.body.enabled)
);

const nearbyHeartbeat = nearbyHandler((req) =>
  nearbyHeartbeatSvc({
    userId: req.user._id,
    lat: req.body.lat,
    lng: req.body.lng,
  })
);

const nearbyPing = nearbyHandler((req) =>
  nearbyPingSvc(req.user._id, req.body.lat, req.body.lng)
);

const sendNearbyRequest = nearbyHandler((req) =>
  sendNearbyRequestSvc({
    senderId: req.user._id,
    receiverId: req.body.userId,
    message: req.body.message,
  })
);

module.exports = {
  searchUsers,
  getUserById,
  matchContacts,
  sendFriendRequest,
  getPendingRequests,
  updateFriendRequest,
  updateProfile,
  getFriends,
  blockUser,
  unblockUser,
  getBlockedUsers,
  setNearbySettings,
  nearbyHeartbeat,
  nearbyPing,
  sendNearbyRequest,
};
