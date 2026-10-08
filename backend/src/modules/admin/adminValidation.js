const { str, num, arr, bool, objectId, url, isoDate } = require('../../utils/validators');

const ROLES = ['user', 'admin'];
const CHAT_TYPES = ['direct', 'group', 'community'];
const CALL_TYPES = ['audio', 'video'];
const CALL_STATUSES = ['ringing', 'ongoing', 'ended', 'missed', 'declined', 'failed'];
const MESSAGE_TYPES = [
  'text', 'image', 'video', 'audio', 'voice', 'file',
  'gif', 'sticker', 'location', 'contact', 'system',
];
const BROADCAST_TARGETS = ['all', 'premium', 'verified', 'unverified', 'user'];

const pagination = (defaultLimit) => ({
  page: num({ integer: true, min: 1, clamp: true, default: 1 }),
  limit: num({ integer: true, min: 1, max: 200, clamp: true, default: defaultLimit }),
});

const listUsers = {
  query: {
    ...pagination(20),
    search: str({ max: 100 }),
    role: str({ values: ROLES }),
    isPremium: bool(),
    isVerified: bool(),
  },
};

const updateUser = {
  body: {
    role: str({ values: ROLES }),
    isPremium: bool(),
    isVerified: bool(),
    premiumExpiry: isoDate(),
  },
};

const updateSystemSettings = {
  body: {
    allowNewRegistrations: bool(),
    maintenanceMode: bool(),
    allowedEmailDomains: arr({ of: str({ max: 253 }), max: 100 }),
    latestVersionName: str({ max: 32 }),
    latestVersionCode: num({ integer: true, min: 0 }),
    minRequiredVersionCode: num({ integer: true, min: 0 }),
    releaseNotes: str({ max: 5000 }),
    isForceUpdate: bool(),
  },
};

const getAuditLogs = { query: pagination(50) };

const listChats = {
  query: { ...pagination(20), chatType: str({ values: CHAT_TYPES }) },
};

const listMessages = {
  query: {
    ...pagination(50),
    chatId: objectId(),
    senderId: objectId(),
    messageType: str({ values: MESSAGE_TYPES }),
  },
};

const listStories = {
  query: { ...pagination(20), userId: objectId(), category: str({ max: 50 }) },
};

const listCalls = {
  query: {
    ...pagination(20),
    status: str({ values: CALL_STATUSES }),
    callType: str({ values: CALL_TYPES }),
  },
};

const broadcastNotification = {
  body: {
    target: str({ required: true, values: BROADCAST_TARGETS }),
    userId: objectId(),
    title: str({ required: true, max: 150 }),
    body: str({ required: true, max: 1000 }),
    imageUrl: url(),
  },
  check: (req) =>
    req.body.target === 'user' && !req.body.userId
      ? 'userId is required for target "user"'
      : null,
};

const getStatsTimeseries = {
  query: { days: num({ integer: true, min: 1, max: 90, clamp: true, default: 30 }) },
};

const globalSearch = {
  query: { q: str({ max: 100, default: '' }) },
};

module.exports = {
  listUsers,
  updateUser,
  updateSystemSettings,
  getAuditLogs,
  listChats,
  listMessages,
  listStories,
  listCalls,
  broadcastNotification,
  getStatsTimeseries,
  globalSearch,
};
