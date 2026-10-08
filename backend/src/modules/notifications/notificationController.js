const Notification = require('../../models/Notification');
const logger = require('../../utils/logger');

// 1. GET ALL NOTIFICATIONS
const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const list = await Notification.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ success: true, data: list });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. MARK INDIVIDUAL NOTIFICATION AS READ
const markAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // notificationId

    const notif = await Notification.findOneAndUpdate(
      { _id: id, userId },
      { isRead: true },
      { new: true }
    );

    if (!notif) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    return res.json({ success: true, data: notif });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 3. MARK ALL AS READ
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    await Notification.updateMany({ userId, isRead: false }, { isRead: true });
    return res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 4. DELETE NOTIFICATION
const deleteNotification = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params; // notificationId

    const result = await Notification.deleteOne({ _id: id, userId });
    if (result.deletedCount === 0) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    return res.json({ success: true, message: 'Notification deleted successfully' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 5. MOCK TRIGGER PUSH NOTIFICATION
const triggerMockNotification = async (req, res) => {
  try {
    const userId = req.user.id;
    const { type, title, body, metadata } = req.body;

    const notif = await Notification.create({
      userId,
      type,
      title,
      body,
      metadata: metadata || {},
    });

    logger.info(`[FCM MOCK] Triggered push notification to User ${userId}: "${title} - ${body}"`);

    return res.status(201).json({ success: true, data: notif });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  triggerMockNotification,
};
