const {
  str, num, arr, bool, obj, objectId, url, isoDate, mimeType,
} = require('../../utils/validators');
const { MAX_CONTENT, MAX_TEXT_CHARS } = require('./messageLimits');

const CHAT_TYPES = ['direct', 'group', 'community'];
const MESSAGE_TYPES = [
  'text', 'image', 'video', 'audio', 'voice', 'file',
  'gif', 'sticker', 'location', 'contact', 'system',
];
const PERMISSION_VALUES = ['everyone', 'admins'];
const MEETING_TYPES = ['instant', 'scheduled'];

const MAX_PARTICIPANTS = 256;
const MAX_MEMBERS_PER_CALL = 100;

const getConversations = {
  query: {
    includeArchived: bool({ default: false }),
    archivedOnly: bool({ default: false }),
  },
};

const createConversation = {
  body: {
    type: str({ required: true, values: CHAT_TYPES }),
    name: str({ max: 100 }),
    participantIds: arr({ of: objectId(), max: MAX_PARTICIPANTS, default: () => [] }),
    imageUrl: url(),
    description: str({ max: 1000 }),
    spaceId: objectId(),
    category: str({ max: 50 }),
  },
};

const updateConversation = {
  body: {
    name: str({ max: 100 }),
    image: url(),
    imageUrl: url(),
    description: str({ max: 1000 }),
    bio: str({ max: 1000 }),
  },
};

const addMembers = {
  body: {
    userIds: arr({ required: true, of: objectId(), min: 1, max: MAX_MEMBERS_PER_CALL }),
  },
};

const setConversationPreferences = {
  body: {
    isPinned: bool(),
    isMuted: bool(),
    isArchived: bool(),
    hidden: bool(),
  },
};

// Accepts both the nested { permissions: {...} } form and the flat one, which
// is what the controller already unwraps.
const permissionFields = {
  sendMessages: str({ values: PERMISSION_VALUES }),
  editInfo: str({ values: PERMISSION_VALUES }),
  addMembers: str({ values: PERMISSION_VALUES }),
};

const updateGroupPermissions = {
  body: {
    permissions: obj({ shape: permissionFields }),
    ...permissionFields,
  },
};

const getMessages = {
  query: {
    limit: num({ integer: true, min: 1, max: 100, clamp: true, default: 50 }),
    before: isoDate(),
    after: objectId(),
  },
};

const getSharedMedia = {
  query: {
    limit: num({ integer: true, min: 1, max: 100, clamp: true, default: 30 }),
    before: isoDate(),
  },
};

const mediaShape = {
  url: url(),
  mediaUrl: url(),
  thumbnail: url(),
  fileName: str({ max: 255 }),
  mimeType: mimeType(),
  size: num({ min: 0 }),
  duration: num({ min: 0 }),
};

const sendMessage = {
  body: {
    messageType: str({ values: MESSAGE_TYPES, default: 'text' }),
    content: str({
      max: MAX_CONTENT,
      maxMessage: `A message can be at most ${MAX_TEXT_CHARS} characters`,
      default: '',
    }),
    media: obj({ shape: mediaShape }),
    mediaUrl: url(),
    mediaMeta: obj({ shape: mediaShape }),
    replyToId: objectId(),
  },
  check: (req) => {
    const { content, media, mediaUrl } = req.body;
    const hasMedia = !!(mediaUrl || media?.url || media?.mediaUrl);
    return content || hasMedia ? null : 'A message needs content or media';
  },
};

const markRead = {
  body: { senderId: objectId() },
};

const reactToMessage = {
  body: { emoji: str({ max: 16 }) },
};

const starMessage = {
  body: { star: bool({ required: true }) },
};

const pinMessage = {
  body: { isPinned: bool({ required: true }) },
};

const deleteMessage = {
  body: { forEveryone: bool({ default: false }) },
};

// The name becomes part of the object key, so path separators are out.
const uploadMedia = {
  body: {
    fileName: str({
      required: true,
      max: 255,
      pattern: /^[^/\\\0]+$/,
      message: 'must not contain path separators',
    }),
    mimeType: mimeType({ required: true }),
  },
};

const getCommunities = {
  query: { category: str({ max: 50 }) },
};

const createCommunity = {
  body: {
    name: str({ required: true, max: 100 }),
    description: str({ max: 1000 }),
    iconUrl: url(),
    imageUrl: url(),
    category: str({ max: 50 }),
  },
};

const createEvent = {
  body: {
    title: str({ required: true, max: 150 }),
    description: str({ max: 2000 }),
    startTime: isoDate(),
    endTime: isoDate(),
    location: str({ max: 200 }),
    instant: bool(),
  },
  check: (req) => {
    const { startTime, endTime } = req.body;
    if (!startTime || !endTime) return null;
    return new Date(endTime) > new Date(startTime) ? null : 'endTime must be after startTime';
  },
};

const createMeeting = {
  body: {
    type: str({ values: MEETING_TYPES, default: 'instant' }),
    scheduledAt: isoDate(),
  },
  check: (req) =>
    req.body.type === 'scheduled' && !req.body.scheduledAt
      ? 'scheduledAt is required for a scheduled meeting'
      : null,
};

module.exports = {
  getConversations,
  createConversation,
  updateConversation,
  addMembers,
  setConversationPreferences,
  updateGroupPermissions,
  getMessages,
  getSharedMedia,
  sendMessage,
  markRead,
  reactToMessage,
  starMessage,
  pinMessage,
  deleteMessage,
  uploadMedia,
  getCommunities,
  createCommunity,
  createEvent,
  createMeeting,
};
