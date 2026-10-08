const express = require('express');
const router = express.Router();
const {
  getConversations,
  getConversationById,
  createConversation,
  updateConversation,
  addMembers,
  removeMember,
  leaveConversation,
  deleteConversation,
  getMessages,
  getSharedMedia,
  sendMessage,
  markRead,
  setConversationPreferences,
  reactToMessage,
  starMessage,
  deleteMessage,
  uploadMedia,
  pinMessage,
  getPinnedMessages,
  updateGroupPermissions,
  getCommunities,
  createCommunity,
  joinCommunity,
  leaveCommunity,
  getCommunityMembers,
  getCommunityPreviewHandler,
  createEvent,
  getEvents,
  createMeeting,
  markDelivered,
  getHomeDashboard
} = require('./chatController');
const { protect } = require('../../middleware/authMiddleware');
const { rateLimiter } = require('../../middleware/rateLimit');
const { validate, registerIdParams } = require('../../middleware/validate');
const schema = require('./chatValidation');

const sendLimiter = rateLimiter({ points: 120, duration: 60, keyPrefix: 'rl:msg-send' });
const uploadLimiter = rateLimiter({ points: 30, duration: 60, keyPrefix: 'rl:media-upload' });
const writeLimiter = rateLimiter({ points: 60, duration: 60, keyPrefix: 'rl:chat-write' });

registerIdParams(router);

// ─── CONVERSATIONS (direct, group, community channels) ─────────────────────
router.get('/conversations', protect, validate(schema.getConversations), getConversations);
router.post('/conversations', protect, writeLimiter, validate(schema.createConversation), createConversation);
router.get('/conversations/:id', protect, getConversationById);
router.patch('/conversations/:id', protect, validate(schema.updateConversation), updateConversation);
router.delete('/conversations/:id/leave', protect, leaveConversation);
router.delete('/conversations/:id', protect, writeLimiter, deleteConversation);
router.patch('/conversations/:id/preferences', protect, validate(schema.setConversationPreferences), setConversationPreferences);
router.patch('/conversations/:id/permissions', protect, validate(schema.updateGroupPermissions), updateGroupPermissions);
// ─── GROUP / CHANNEL MEMBERSHIP ─────────────────────────────────────────────
router.post('/conversations/:id/members', protect, validate(schema.addMembers), addMembers);
router.delete('/conversations/:id/members/:userId', protect, removeMember);

// ─── MESSAGES ────────────────────────────────────────────────────────────────
router.get('/conversations/:id/messages', protect, validate(schema.getMessages), getMessages);
router.get('/conversations/:id/media', protect, validate(schema.getSharedMedia), getSharedMedia);
router.post('/conversations/:id/messages', protect, sendLimiter, validate(schema.sendMessage), sendMessage);
router.post('/messages/:id/deliver', protect, markDelivered);
router.patch('/conversations/:id/read', protect, validate(schema.markRead), markRead);
router.post('/messages/:id/react', protect, validate(schema.reactToMessage), reactToMessage);
router.post('/messages/:id/star', protect, validate(schema.starMessage), starMessage);
router.post('/messages/:id/pin', protect, validate(schema.pinMessage), pinMessage);
router.get('/conversations/:id/pinned-messages', protect, getPinnedMessages);
router.delete('/messages/:id', protect, validate(schema.deleteMessage), deleteMessage);

// ─── MEDIA ───────────────────────────────────────────────────────────────────
router.post('/media/upload', protect, uploadLimiter, validate(schema.uploadMedia), uploadMedia);

// ─── COMMUNITIES (spaces) ────────────────────────────────────────────────────
router.get('/communities', protect, validate(schema.getCommunities), getCommunities);
router.post('/communities', protect, writeLimiter, validate(schema.createCommunity), createCommunity);
router.post('/communities/:id/join', protect, joinCommunity);
router.delete('/communities/:id/leave', protect, leaveCommunity);
router.get('/communities/:id/members', protect, getCommunityMembers);
// Deep-link landing: intentionally NOT gated by membership — the whole point
// is letting someone who tapped an invite link see what they're joining.
router.get('/communities/:id/preview', protect, getCommunityPreviewHandler);

// ─── EVENTS & MEETINGS ───────────────────────────────────────────────────────
router.post('/communities/:id/events', protect, writeLimiter, validate(schema.createEvent), createEvent);
router.get('/communities/:id/events', protect, getEvents);
router.post('/meetings', protect, writeLimiter, validate(schema.createMeeting), createMeeting);

// ─── Home ───────────────────────────────────────────────────────
// router.get('/dashboard', protect, getHomeDashboard);

module.exports = router;
