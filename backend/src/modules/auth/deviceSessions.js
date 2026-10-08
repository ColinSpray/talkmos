const jwt = require('jsonwebtoken');
const DeviceSession = require('../../models/DeviceSession');
const { getActiveFcmSessions, invalidateUserSessions } = require('../../services/deviceSessionCache');

const JWT_SECRET = process.env.JWT_SECRET;

const MAX_DEVICE_SESSIONS = 15;

const generateToken = (userId, device) => {
  const payload = device
    ? { id: userId, deviceId: device.deviceId, tokenVersion: device.tokenVersion }
    : { id: userId };
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
};

const upsertDeviceSession = async (userId, device, req) => {
  if (!device || !device.deviceId) return null;

  const { deviceId, deviceName, platform, fcmToken } = device;
  const ip = req?.ip || req?.headers?.['x-forwarded-for'] || '';
  const userAgent = req?.headers?.['user-agent'] || '';
  const now = new Date();

  const session = await DeviceSession.findOneAndUpdate(
    { userId, deviceId },
    {
      $set: {
        deviceName: deviceName || '',
        platform: platform || 'other',
        // Only overwrite when the client actually sent one, so a login that
        // didn't include a fresh push token doesn't blank out the last one.
        ...(fcmToken ? { fcmToken } : {}),
        ip,
        userAgent,
        isActive: true,
        loginAt: now,
        lastActiveAt: now,
        loggedOutAt: null,
      },
      $setOnInsert: { userId, deviceId, tokenVersion: 0 },
    },
    { new: true, upsert: true }
  );

  await invalidateUserSessions(userId, deviceId);

  await pruneDeviceSessions(userId);
  return session;
};

/** Evicts the oldest logged-out sessions once a user's count exceeds the cap. */
const pruneDeviceSessions = async (userId) => {
  const count = await DeviceSession.countDocuments({ userId });
  const excess = count - MAX_DEVICE_SESSIONS;
  if (excess <= 0) return;

  const evictable = await DeviceSession.find({ userId, isActive: false })
    .sort({ loggedOutAt: 1, lastActiveAt: 1 })
    .limit(excess)
    .select('_id');
  if (evictable.length === 0) return;

  await DeviceSession.deleteMany({ _id: { $in: evictable.map((d) => d._id) } });
};

const revokeDeviceSession = async (userId, deviceId) => {
  const session = await DeviceSession.findOneAndUpdate(
    { userId, deviceId },
    { $inc: { tokenVersion: 1 }, $set: { isActive: false, loggedOutAt: new Date() } },
    { new: true }
  );
  await invalidateUserSessions(userId, deviceId);
  return session;
};

const getActiveDeviceTokens = async (userId, excludeDeviceIds) => {
  const sessions = await getActiveFcmSessions(userId);
  const filtered = excludeDeviceIds && excludeDeviceIds.size > 0
    ? sessions.filter((s) => !excludeDeviceIds.has(s.deviceId))
    : sessions;
  return Array.from(new Set(filtered.map((s) => s.fcmToken).filter(Boolean)));
};

module.exports = {
  MAX_DEVICE_SESSIONS,
  generateToken,
  upsertDeviceSession,
  pruneDeviceSessions,
  revokeDeviceSession,
  getActiveDeviceTokens,
};
