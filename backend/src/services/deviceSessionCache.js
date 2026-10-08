const DeviceSession = require('../models/DeviceSession');
const cache = require('./cache');

const SESSION_TTL_SECONDS = 60;
const FCM_TTL_SECONDS = 60;

const sessionKey = (userId, deviceId) => `session:${userId}:${deviceId}`;
const fcmKey = (userId) => `fcm:${userId}`;


const getSessionCheck = async (userId, deviceId) => {
  const k = sessionKey(userId, deviceId);
  const cached = await cache.get(k);
  if (cached) return cached;

  const device = await DeviceSession.findOne({ userId, deviceId })
    .select('isActive tokenVersion')
    .lean();

  const value = device
    ? { found: true, isActive: device.isActive, tokenVersion: device.tokenVersion }
    : { found: false };

  await cache.set(k, value, SESSION_TTL_SECONDS);
  return value;
};

const invalidateSession = (userId, deviceId) => cache.del(sessionKey(userId, deviceId));

/** Raw {fcmToken, deviceId} pairs for a user's active devices — same shape deviceSessions.getActiveDeviceTokens filters after fetching. */
const getActiveFcmSessions = async (userId) => {
  const k = fcmKey(userId);
  const cached = await cache.get(k);
  if (cached) return cached;

  const sessions = await DeviceSession.find({ userId, isActive: true, fcmToken: { $ne: '' } })
    .select('fcmToken deviceId')
    .lean();

  await cache.set(k, sessions, FCM_TTL_SECONDS);
  return sessions;
};

const invalidateFcmSessions = (userId) => cache.del(fcmKey(userId));

/** Call after any DeviceSession write — covers both caches this module owns. */
const invalidateUserSessions = (userId, deviceId) => {
  const tasks = [invalidateFcmSessions(userId)];
  if (deviceId) tasks.push(invalidateSession(userId, deviceId));
  return Promise.all(tasks);
};

module.exports = {
  getSessionCheck,
  invalidateSession,
  getActiveFcmSessions,
  invalidateFcmSessions,
  invalidateUserSessions,
};
