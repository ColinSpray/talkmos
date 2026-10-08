const mongoose = require('mongoose');
const cache = require('../services/cache');

const CACHE_KEY = 'system:settings';
const CACHE_TTL_SECONDS = 60 * 60; // 1 hour

const SystemSettingSchema = new mongoose.Schema(
  {
    allowNewRegistrations: {
      type: Boolean,
      default: true,
    },
    maintenanceMode: {
      type: Boolean,
      default: false,
    },
    allowedEmailDomains: {
      type: [String],
      default: [],
    },
    latestVersionName: {
      type: String,
      default: '1.0.0',
    },
    latestVersionCode: {
      type: Number,
      default: 1,
    },
    minRequiredVersionCode: {
      type: Number,
      default: 1,
    },
    releaseNotes: {
      type: String,
      default: 'Bug fixes and performance improvements.',
    },
    isForceUpdate: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);


SystemSettingSchema.statics.getSettings = async function () {
  const cached = await cache.get(CACHE_KEY);
  if (cached) return cached;
  let doc = await this.findOne().sort({ createdAt: 1 });
  if (!doc) {
    doc = await this.create({});
  }
  const settings = doc.toObject();

  await cache.set(CACHE_KEY, settings, CACHE_TTL_SECONDS);

  return settings;
};

SystemSettingSchema.statics.invalidateCache = function () {
  return cache.del(CACHE_KEY);
};

module.exports = mongoose.model('SystemSetting', SystemSettingSchema);