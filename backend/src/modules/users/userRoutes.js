const express = require('express');
const router = express.Router();
const { protect } = require('../../middleware/authMiddleware');
const { rateLimiter } = require('../../middleware/rateLimit');
const { validate, registerIdParams } = require('../../middleware/validate');
const schema = require('./userValidation');

const contactsLimiter = rateLimiter({ points: 10, duration: 300, keyPrefix: 'rl:contacts' });
const searchLimiter = rateLimiter({ points: 60, duration: 60, keyPrefix: 'rl:user-search' });
const friendLimiter = rateLimiter({ points: 60, duration: 300, keyPrefix: 'rl:friend-req' });

// Heartbeat runs on a 30s timer for everyone with the screen open, so this is
// sized to pass normal use and catch a client stuck in a retry loop.
const nearbyLimiter = rateLimiter({ points: 30, duration: 60, keyPrefix: 'rl:nearby' });

const nearbyRequestLimiter = rateLimiter({
  points: 5,
  duration: 86400,
  keyPrefix: 'rl:nearby-req',
  key: (req) => String(req.user._id),
  refundOnFailure: true,
});

const nearbySettingsLimiter = rateLimiter({
  points: 20,
  duration: 300,
  keyPrefix: 'rl:nearby-settings',
  key: (req) => String(req.user._id),
});
const {
  searchUsers,
  getUserById,
  matchContacts,
  sendFriendRequest,
  getPendingRequests,
  updateFriendRequest,
  getFriends,
  updateProfile,
  blockUser,
  unblockUser,
  getBlockedUsers,
  setNearbySettings,
  nearbyHeartbeat,
  nearbyPing,
  sendNearbyRequest,
} = require('./userController');

registerIdParams(router);

router.get('/search', protect, searchLimiter, validate(schema.searchUsers), searchUsers);
router.post('/contacts/match', protect, contactsLimiter, validate(schema.matchContacts), matchContacts);
router.put('/profile', protect, validate(schema.updateProfile), updateProfile);

// Friend Requests and Friends List
router.post('/friend-requests', protect, friendLimiter, validate(schema.sendFriendRequest), sendFriendRequest);
router.get('/friend-requests/pending', protect, getPendingRequests);
router.put('/friend-requests/:id', protect, validate(schema.updateFriendRequest), updateFriendRequest);
router.get('/friends', protect, getFriends);

// Nearby (coarse-position proximity discovery)
router.patch('/nearby/settings', protect, nearbySettingsLimiter, validate(schema.setNearbySettings), setNearbySettings);
router.post('/nearby/heartbeat', protect, nearbyLimiter, validate(schema.nearbyHeartbeat), nearbyHeartbeat);
// Fired on app foreground from any screen, so it is bounded separately from
// the heartbeat's own cadence.
router.post('/nearby/ping', protect, rateLimiter({ points: 20, duration: 300, keyPrefix: 'rl:nearby-ping' }), validate(schema.nearbyPing), nearbyPing);
router.post('/nearby/request', protect, nearbyRequestLimiter, validate(schema.sendNearbyRequest), sendNearbyRequest);

// Blocking
router.get('/blocked', protect, getBlockedUsers);
router.post('/block/:id', protect, blockUser);
router.post('/unblock/:id', protect, unblockUser);

// Public profile lookup, for a chat deep link — kept last so it can't shadow
// the literal routes above (/search, /friends, /blocked, etc).
router.get('/:id', protect, getUserById);

module.exports = router;
