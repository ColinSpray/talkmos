const User = require('../../models/User');
const SystemSetting = require('../../models/SystemSetting');
const Message = require('../../models/Message');
const Chat = require('../../models/Chat');
const ChatMember = require('../../models/ChatMember');
const Call = require('../../models/Call');
const CallParticipant = require('../../models/CallParticipant');
const Story = require('../../models/Story');
const AuditLog = require('../../models/AuditLog');
const DeviceSession = require('../../models/DeviceSession');
const FriendRequest = require('../../models/FriendRequest');
const Notification = require('../../models/Notification');
const { revokeDeviceSession } = require('../auth/deviceSessions');
const { sendMulticastNotification } = require('../../services/fcmService');
const userCache = require('../../services/userCache');
const logger = require('../../utils/logger');

// 1. GET SYSTEM OPERATIONAL STATS
const getStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const premiumUsers = await User.countDocuments({ isPremium: true });
    const verifiedUsers = await User.countDocuments({ isVerified: true });
    const adminUsers = await User.countDocuments({ role: 'admin' });
    const totalMessages = await Message.countDocuments();
    const totalChats = await Chat.countDocuments();
    const totalCalls = await Call.countDocuments();

    return res.json({
      success: true,
      data: {
        users: {
          total: totalUsers,
          premium: premiumUsers,
          verified: verifiedUsers,
          admin: adminUsers,
        },
        stats: {
          messages: totalMessages,
          chats: totalChats,
          calls: totalCalls,
        },
      },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. GET ALL USERS (WITH FILTERS, SEARCH, PAGINATION)
const listUsers = async (req, res) => {
  try {
    const { page, limit, search, role, isPremium, isVerified } = req.query;
    const skip = (page - 1) * limit;

    const query = {};

    if (search) {
      const searchRegex = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      query.$or = [
        { name: searchRegex },
        { fullName: searchRegex },
        { email: searchRegex },
        { phone: searchRegex },
        { username: searchRegex },
      ];
    }

    if (role) query.role = role;
    if (isPremium !== undefined) query.isPremium = isPremium;
    if (isVerified !== undefined) query.isVerified = isVerified;

    const users = await User.find(query)
      .select('-password')
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });

    const total = await User.countDocuments(query);

    return res.json({
      success: true,
      data: users,
      pagination: {
        total,
        page,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 3. UPDATE USER STATUS / ROLE
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { role, isPremium, isVerified, premiumExpiry } = req.body;

    const updateFields = {};
    if (role !== undefined) updateFields.role = role;
    if (isPremium !== undefined) updateFields.isPremium = isPremium;
    if (isVerified !== undefined) updateFields.isVerified = isVerified;
    if (premiumExpiry !== undefined) updateFields.premiumExpiry = premiumExpiry;

    const user = await User.findByIdAndUpdate(id, updateFields, { new: true }).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    await userCache.invalidateUser(id);

    logger.info(`[ADMIN] User ${user.phone || user.email} updated by admin ${req.user.phone || req.user.email}`);

    return res.json({ success: true, data: user });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 4. DELETE USER
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    // Prevent deleting oneself
    if (id === req.user.id.toString()) {
      return res.status(400).json({ success: false, message: 'You cannot delete your own administrative account' });
    }

    const user = await User.findByIdAndDelete(id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    await userCache.invalidateUser(id);

    logger.info(`[ADMIN] User ${user.phone || user.email} deleted by admin ${req.user.phone || req.user.email}`);

    return res.json({ success: true, message: 'User deleted successfully' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 5. GET GLOBAL SYSTEM SETTINGS
const getSystemSettings = async (req, res) => {
  try {
    const settings = await SystemSetting.getSettings();
    return res.json({ success: true, data: settings });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 6. UPDATE GLOBAL SYSTEM SETTINGS
const updateSystemSettings = async (req, res) => {
  try {
    const {
      allowNewRegistrations,
      maintenanceMode,
      allowedEmailDomains,
      latestVersionName,
      latestVersionCode,
      minRequiredVersionCode,
      releaseNotes,
      isForceUpdate,
    } = req.body;

    const current = await SystemSetting.getSettings();

    const updateFields = {};
    if (allowNewRegistrations !== undefined) updateFields.allowNewRegistrations = allowNewRegistrations;
    if (maintenanceMode !== undefined) updateFields.maintenanceMode = maintenanceMode;
    if (allowedEmailDomains !== undefined) updateFields.allowedEmailDomains = allowedEmailDomains;
    if (latestVersionName !== undefined) updateFields.latestVersionName = latestVersionName;
    if (latestVersionCode !== undefined) updateFields.latestVersionCode = latestVersionCode;
    if (minRequiredVersionCode !== undefined) updateFields.minRequiredVersionCode = minRequiredVersionCode;
    if (releaseNotes !== undefined) updateFields.releaseNotes = releaseNotes;
    if (isForceUpdate !== undefined) updateFields.isForceUpdate = isForceUpdate;

    const settings = await SystemSetting.findByIdAndUpdate(current._id, { $set: updateFields }, { new: true });
    await SystemSetting.invalidateCache();

    logger.info(`[ADMIN] System settings updated by admin ${req.user.phone || req.user.email}`);

    return res.json({ success: true, data: settings });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 7. GET AUDIT LOGS
const getAuditLogs = async (req, res) => {
  try {
    const { page, limit } = req.query;
    const skip = (page - 1) * limit;

    const logs = await AuditLog.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('adminId', 'name email phone');

    const total = await AuditLog.countDocuments();

    return res.json({
      success: true,
      data: logs,
      pagination: { total, page, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 8. LIST CHATS/GROUPS/COMMUNITIES (MODERATION)
const listChats = async (req, res) => {
  try {
    const { page, limit, chatType } = req.query;
    const skip = (page - 1) * limit;

    const query = {};
    if (chatType) query.chatType = chatType;

    const chats = await Chat.find(query)
      .populate('sender', 'name email phone')
      .populate('receiver', 'name email phone')
      .populate('spaceId', 'name imageUrl')
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });

    const total = await Chat.countDocuments(query);

    return res.json({
      success: true,
      data: chats,
      pagination: { total, page, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 9. DELETE A CHAT/GROUP/COMMUNITY (MODERATION)
const deleteChat = async (req, res) => {
  try {
    const { id } = req.params;
    const chat = await Chat.findByIdAndDelete(id);
    if (!chat) {
      return res.status(404).json({ success: false, message: 'Chat not found' });
    }
    await Message.deleteMany({ chatId: id });

    logger.info(`[ADMIN] Chat ${id} deleted by admin ${req.user.phone || req.user.email}`);

    return res.json({ success: true, message: 'Chat deleted successfully' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 10. LIST MESSAGES (MODERATION — SEARCH BY CHAT/SENDER)
const listMessages = async (req, res) => {
  try {
    const { page, limit, chatId, senderId, messageType } = req.query;
    const skip = (page - 1) * limit;

    const query = {};
    if (chatId) query.chatId = chatId;
    if (senderId) query.senderId = senderId;
    if (messageType) query.messageType = messageType;

    const messages = await Message.find(query)
      .populate('senderId', 'name email phone')
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });

    const total = await Message.countDocuments(query);

    return res.json({
      success: true,
      data: messages,
      pagination: { total, page, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 11. DELETE A MESSAGE (MODERATION — HARD DELETE, NOT THE SOFT PER-USER ONE)
const deleteMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const message = await Message.findByIdAndDelete(id);
    if (!message) {
      return res.status(404).json({ success: false, message: 'Message not found' });
    }

    logger.info(`[ADMIN] Message ${id} deleted by admin ${req.user.phone || req.user.email}`);

    return res.json({ success: true, message: 'Message deleted successfully' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 12. LIST STORIES (MODERATION)
const listStories = async (req, res) => {
  try {
    const { page, limit, userId, category } = req.query;
    const skip = (page - 1) * limit;

    const query = {};
    if (userId) query.userId = userId;
    if (category) query.category = category;

    const stories = await Story.find(query)
      .populate('userId', 'name email phone')
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });

    const total = await Story.countDocuments(query);

    return res.json({
      success: true,
      data: stories,
      pagination: { total, page, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 13. DELETE A STORY (MODERATION)
const deleteStory = async (req, res) => {
  try {
    const { id } = req.params;
    const story = await Story.findByIdAndDelete(id);
    if (!story) {
      return res.status(404).json({ success: false, message: 'Story not found' });
    }

    logger.info(`[ADMIN] Story ${id} deleted by admin ${req.user.phone || req.user.email}`);

    return res.json({ success: true, message: 'Story deleted successfully' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 14. GET A SINGLE USER'S FULL PROFILE (DEVICES, FRIENDS, CHATS, CALLS)
const getUserDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id).select('-password').lean();
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const [devices, friendships, directChats, memberships, callParticipations] = await Promise.all([
      DeviceSession.find({ userId: id }).sort({ lastActiveAt: -1 }).select('-fcmToken').lean(),
      FriendRequest.find({ status: 'accepted', $or: [{ sender: id }, { receiver: id }] })
        .populate('sender', 'name username email phone avatarUrl status')
        .populate('receiver', 'name username email phone avatarUrl status')
        .lean(),
      Chat.find({ chatType: 'direct', $or: [{ sender: id }, { receiver: id }] })
        .sort({ updatedAt: -1 })
        .limit(20)
        .populate('sender', 'name')
        .populate('receiver', 'name')
        .lean(),
      ChatMember.find({ userId: id, leftAt: null })
        .populate('chatId', 'chatType createdAt')
        .limit(20)
        .lean(),
      CallParticipant.find({ userId: id })
        .sort({ createdAt: -1 })
        .limit(20)
        .populate({
          path: 'callId',
          select: 'callType status startedAt endedAt duration initiatedBy',
          populate: { path: 'initiatedBy', select: 'name email phone' },
        })
        .lean(),
    ]);

    const friends = friendships.map((f) =>
      String(f.sender._id) === String(id) ? f.receiver : f.sender,
    );

    const chats = [
      ...directChats.map((c) => ({
        _id: c._id,
        chatType: c.chatType,
        other: String(c.sender?._id) === String(id) ? c.receiver : c.sender,
        updatedAt: c.updatedAt,
      })),
      ...memberships
        .filter((m) => m.chatId)
        .map((m) => ({
          _id: m.chatId._id,
          chatType: m.chatId.chatType,
          role: m.role,
          updatedAt: m.chatId.createdAt,
        })),
    ];

    const calls = callParticipations
      .filter((cp) => cp.callId)
      .map((cp) => ({
        _id: cp.callId._id,
        callType: cp.callId.callType,
        status: cp.callId.status,
        startedAt: cp.callId.startedAt,
        endedAt: cp.callId.endedAt,
        duration: cp.callId.duration,
        initiatedBy: cp.callId.initiatedBy,
        myStatus: cp.status,
      }));

    return res.json({ success: true, data: { user, devices, friends, chats, calls } });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 15. FORCE-LOGOUT ONE OF A USER'S DEVICES
const revokeUserDevice = async (req, res) => {
  try {
    const { id, deviceId } = req.params;
    const session = await revokeDeviceSession(id, deviceId);
    if (!session) {
      return res.status(404).json({ success: false, message: 'Device session not found' });
    }

    logger.info(`[ADMIN] Device ${deviceId} for user ${id} revoked by admin ${req.user.phone || req.user.email}`);

    return res.json({ success: true, message: 'Device logged out' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 16. LIST CALLS (MONITORING)
const listCalls = async (req, res) => {
  try {
    const { page, limit, status, callType } = req.query;
    const skip = (page - 1) * limit;

    const query = {};
    if (status) query.status = status;
    if (callType) query.callType = callType;

    const calls = await Call.find(query)
      .populate('initiatedBy', 'name email phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Call.countDocuments(query);

    return res.json({
      success: true,
      data: calls,
      pagination: { total, page, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 17. GET A SINGLE CALL WITH PARTICIPANTS
const getCallDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const call = await Call.findById(id).populate('initiatedBy', 'name email phone').lean();
    if (!call) {
      return res.status(404).json({ success: false, message: 'Call not found' });
    }

    const participants = await CallParticipant.find({ callId: id })
      .populate('userId', 'name email phone')
      .lean();

    return res.json({ success: true, data: { ...call, participants } });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 18. BROADCAST A NOTIFICATION TO ONE USER OR EVERYONE
const broadcastNotification = async (req, res) => {
  try {
    const { target, userId, title, body, imageUrl } = req.body;

    let recipientIds;
    if (target === 'user') {
      const user = await User.findById(userId).select('_id');
      if (!user) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      recipientIds = [user._id];
    } else {
      const filterQuery =
        target === 'premium'
          ? { isPremium: true }
          : target === 'verified'
            ? { isVerified: true }
            : target === 'unverified'
              ? { isVerified: false }
              : {};
      recipientIds = (await User.find(filterQuery).select('_id').lean()).map((u) => u._id);
    }

    if (recipientIds.length === 0) {
      return res.json({ success: true, data: { recipients: 0, pushed: 0, failed: 0 } });
    }

    await Notification.insertMany(
      recipientIds.map((uid) => ({
        userId: uid,
        type: 'system',
        title,
        body,
        metadata: imageUrl ? { imageUrl } : {},
      })),
    );

    const sessions = await DeviceSession.find({
      userId: { $in: recipientIds },
      isActive: true,
      fcmToken: { $ne: '' },
    })
      .select('fcmToken')
      .lean();

    const pushResult = await sendMulticastNotification(
      sessions.map((s) => s.fcmToken),
      title,
      body,
      { type: 'system', imageUrl },
    );

    logger.info(
      `[ADMIN] Broadcast "${title}" (target: ${target}) sent to ${recipientIds.length} user(s) by admin ${req.user.phone || req.user.email}`,
    );

    return res.json({
      success: true,
      data: {
        recipients: recipientIds.length,
        pushed: pushResult.successCount,
        failed: pushResult.failureCount,
      },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 19. DASHBOARD TREND CHARTS — DAILY SIGNUPS / MESSAGES / CALLS
const getStatsTimeseries = async (req, res) => {
  try {
    const { days } = req.query;
    const since = new Date();
    since.setDate(since.getDate() - (days - 1));
    since.setHours(0, 0, 0, 0);

    const dayKey = { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } };
    const groupByDay = [{ $match: { createdAt: { $gte: since } } }, { $group: { _id: dayKey, count: { $sum: 1 } } }];

    const [signups, messages, calls] = await Promise.all([
      User.aggregate(groupByDay),
      Message.aggregate(groupByDay),
      Call.aggregate(groupByDay),
    ]);

    const toMap = (rows) => new Map(rows.map((r) => [r._id, r.count]));
    const signupsMap = toMap(signups);
    const messagesMap = toMap(messages);
    const callsMap = toMap(calls);

    // Aggregation only returns days with activity — fill in the zero days so
    // the chart has one point per day in range, not gaps.
    const series = [];
    for (let i = 0; i < days; i += 1) {
      const d = new Date(since);
      d.setDate(d.getDate() + i);
      const key = d.toISOString().slice(0, 10);
      series.push({
        date: key,
        signups: signupsMap.get(key) || 0,
        messages: messagesMap.get(key) || 0,
        calls: callsMap.get(key) || 0,
      });
    }

    return res.json({ success: true, data: series });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const OBJECT_ID_RE = /^[a-f\d]{24}$/i;

// 20. GLOBAL SEARCH — BY ID ACROSS ENTITIES, OR BY NAME/EMAIL/PHONE FOR USERS
const globalSearch = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.json({ success: true, data: [] });
    }

    const results = [];
    const seen = new Set();
    const push = (type, item) => {
      if (!item) return;
      const key = `${type}:${item._id}`;
      if (seen.has(key)) return;
      seen.add(key);
      results.push({ type, item });
    };

    if (OBJECT_ID_RE.test(q)) {
      const [user, chat, message, story, call] = await Promise.all([
        User.findById(q).select('-password').lean(),
        Chat.findById(q).populate('sender', 'name').populate('receiver', 'name').lean(),
        Message.findById(q).populate('senderId', 'name email phone').lean(),
        Story.findById(q).populate('userId', 'name email phone').lean(),
        Call.findById(q).populate('initiatedBy', 'name email phone').lean(),
      ]);
      push('user', user);
      push('chat', chat);
      push('message', message);
      push('story', story);
      push('call', call);
    }

    const searchRegex = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    const users = await User.find({
      $or: [{ name: searchRegex }, { email: searchRegex }, { phone: searchRegex }, { username: searchRegex }],
    })
      .select('-password')
      .limit(10)
      .lean();
    users.forEach((u) => push('user', u));

    return res.json({ success: true, data: results });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getStats,
  listUsers,
  updateUser,
  deleteUser,
  getSystemSettings,
  updateSystemSettings,
  getAuditLogs,
  listChats,
  deleteChat,
  listMessages,
  deleteMessage,
  listStories,
  deleteStory,
  getUserDetail,
  revokeUserDevice,
  listCalls,
  getCallDetail,
  broadcastNotification,
  getStatsTimeseries,
  globalSearch,
};
