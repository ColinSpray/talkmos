const mongoose = require('mongoose');

const DeviceSessionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    deviceId: {
      type: String,
      required: true,
    },
    deviceName: {
      type: String,
      default: '',
    },
    platform: {
      type: String,
      enum: ['ios', 'android', 'web', 'other'],
      default: 'other',
    },
    fcmToken: {
      type: String,
      default: '',
    },
    tokenVersion: {
      type: Number,
      default: 0,
    },
    ip: {
      type: String,
      default: '',
    },
    userAgent: {
      type: String,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    loginAt: {
      type: Date,
      default: Date.now,
    },
    lastActiveAt: {
      type: Date,
      default: Date.now,
    },
    loggedOutAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

DeviceSessionSchema.index({ userId: 1, deviceId: 1 }, { unique: true });
// Active-session fan-out: which devices to push to, which to disconnect.
DeviceSessionSchema.index({ userId: 1, isActive: 1 });
DeviceSessionSchema.index({ userId: 1, lastActiveAt: -1 });

module.exports = mongoose.model('DeviceSession', DeviceSessionSchema);
