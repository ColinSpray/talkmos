const { str, num, arr, bool, objectId, url, username } = require('../../utils/validators');

const MAX_CONTACTS = 2000;
const MAX_NEARBY_MESSAGE = 200;

const searchUsers = {
  query: { q: str({ required: true, max: 64 }) },
};

const matchContacts = {
  body: {
    phones: arr({ required: true, of: str({ max: 32 }), max: MAX_CONTACTS }),
  },
};

const updateProfile = {
  body: {
    name: str({ max: 80 }),
    username: username(),
    bio: str({ max: 500 }),
    location: str({ max: 120 }),
    language: str({ max: 16 }),
    avatarUrl: url(),
    isPublic: bool(),
  },
};

const sendFriendRequest = {
  body: { receiverId: objectId({ required: true }) },
};

const updateFriendRequest = {
  body: { status: str({ required: true, values: ['accepted', 'rejected'] }) },
};

const setNearbySettings = {
  body: { enabled: bool({ required: true }) },
};

const lat = num({ min: -90, max: 90 });
const lng = num({ min: -180, max: 180 });

// A half-supplied pair would be recorded as a position on the prime meridian.
const coordinatePairCheck = (req) => {
  const hasLat = req.body.lat !== undefined;
  const hasLng = req.body.lng !== undefined;
  if (hasLat !== hasLng) return 'lat and lng must be sent together';
  return null;
};

const nearbyHeartbeat = {
  body: { lat, lng },
  check: coordinatePairCheck,
};

const nearbyPing = {
  body: {
    lat: num({ required: true, min: -90, max: 90 }),
    lng: num({ required: true, min: -180, max: 180 }),
  },
};

const sendNearbyRequest = {
  body: {
    userId: objectId({ required: true }),
    message: str({ required: true, max: MAX_NEARBY_MESSAGE }),
  },
};

module.exports = {
  searchUsers,
  matchContacts,
  updateProfile,
  sendFriendRequest,
  updateFriendRequest,
  setNearbySettings,
  nearbyHeartbeat,
  nearbyPing,
  sendNearbyRequest,
};
