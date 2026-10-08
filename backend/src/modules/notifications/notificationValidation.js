const { str, json } = require('../../utils/validators');

const NOTIFICATION_TYPES = [
  'message', 'call', 'story', 'community', 'event',
  'system', 'friend_request', 'friend_request_accepted',
];

const triggerMockNotification = {
  body: {
    type: str({ required: true, values: NOTIFICATION_TYPES }),
    title: str({ required: true, max: 150 }),
    body: str({ required: true, max: 1000 }),
    metadata: json({ maxBytes: 4096 }),
  },
};

module.exports = { NOTIFICATION_TYPES, triggerMockNotification };
