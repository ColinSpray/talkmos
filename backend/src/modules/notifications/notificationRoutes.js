const express = require('express');
const router = express.Router();
const {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  triggerMockNotification,
} = require('./notificationController');
const { protect } = require('../../middleware/authMiddleware');
const { validate, registerIdParams } = require('../../middleware/validate');
const schema = require('./notificationValidation');

registerIdParams(router);

router.get('/', protect, getNotifications);
router.post('/read-all', protect, markAllAsRead);
router.post('/trigger', protect, validate(schema.triggerMockNotification), triggerMockNotification);
router.post('/:id/read', protect, markAsRead);
router.delete('/:id', protect, deleteNotification);

module.exports = router;
