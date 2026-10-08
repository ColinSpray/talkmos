const express = require('express');
const router = express.Router();
const {
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
} = require('./adminController');
const { protect, adminOnly } = require('../../middleware/authMiddleware');
const auditLog = require('../../middleware/auditLog');
const { validate, stringParam, registerIdParams } = require('../../middleware/validate');
const schema = require('./adminValidation');

router.use(protect);
router.use(adminOnly);
router.use(auditLog);

registerIdParams(router);
router.param('deviceId', stringParam('deviceId', { max: 128 }));

router.get('/stats', getStats);
router.get('/stats/timeseries', validate(schema.getStatsTimeseries), getStatsTimeseries);
router.get('/search', validate(schema.globalSearch), globalSearch);
router.get('/users', validate(schema.listUsers), listUsers);
router.get('/users/:id', getUserDetail);
router.patch('/users/:id', validate(schema.updateUser), updateUser);
router.delete('/users/:id', deleteUser);
router.delete('/users/:id/devices/:deviceId', revokeUserDevice);
router.get('/settings', getSystemSettings);
router.patch('/settings', validate(schema.updateSystemSettings), updateSystemSettings);
router.get('/audit-logs', validate(schema.getAuditLogs), getAuditLogs);
router.get('/chats', validate(schema.listChats), listChats);
router.delete('/chats/:id', deleteChat);
router.get('/messages', validate(schema.listMessages), listMessages);
router.delete('/messages/:id', deleteMessage);
router.get('/stories', validate(schema.listStories), listStories);
router.delete('/stories/:id', deleteStory);
router.get('/calls', validate(schema.listCalls), listCalls);
router.get('/calls/:id', getCallDetail);
router.post('/notifications/broadcast', validate(schema.broadcastNotification), broadcastNotification);

module.exports = router;
