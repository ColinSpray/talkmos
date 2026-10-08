const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const logger = require("../utils/logger");
const notificationQueue = require("./notificationQueue");
const serviceAccount = require("../../credentials/firebase-service-account.json");

let isInitialized = false;

const initializeFirebase = () => {
  if (isInitialized || getApps().length > 0) {
    isInitialized = true;
    return true;
  }

  try {
    initializeApp({
      credential: cert(serviceAccount),
    });

    isInitialized = true;
    logger.info("Firebase Admin SDK initialized successfully.");
  } catch (error) {
    logger.error(`Firebase initialization error: ${error.message}`);
  }

  return isInitialized;
};

const stringifyDataPayload = (data = {}) => {
  return Object.entries(data).reduce((acc, [key, value]) => {
    if (value === undefined || value === null) return acc;
    acc[key] =
      typeof value === "string" ? value : JSON.stringify(value);
    return acc;
  }, {});
};

const sendPushNotification = async (
  registrationToken,
  title,
  body,
  data = {}
) => {
  if (!registrationToken) {
    logger.info("[FCM] Notification skipped: No registration token provided.");
    return false;
  }

  return notificationQueue.publishFCM({
    token: registrationToken,
    title,
    body,
    data: stringifyDataPayload(data),
  });
};

const sendCallNotification = async (
  registrationToken,
  { callId, callType = "audio", initiatorId, initiatorName = "Someone" }
) => {
  if (!registrationToken) {
    logger.info("[FCM] Call notification skipped: No registration token.");
    return false;
  }

  // Data-only message — no `notification` key — so the background handler
  // fires and flutter_callkit_incoming can show the custom FSI UI.
  const message = {
    data: stringifyDataPayload({
      type: "call",
      callId: String(callId),
      callType: String(callType),
      initiatorId: String(initiatorId),
      initiatorName: String(initiatorName),
    }),
    token: registrationToken,
    android: {
      priority: "high",
      ttl: 45000, // 45 seconds, in milliseconds
    },
    apns: {
      headers: {
        "apns-priority": "10",
        "apns-push-type": "voip",          // Use VoIP-style push on iOS
        "apns-expiration": "45",
      },
      payload: {
        aps: {
          "content-available": 1,          // Silent push to wake app
          sound: "default",
          category: "INCOMING_CALL",
        },
      },
    },
  };

  try {
    const response = await getMessaging().send(message);
    logger.info(`[FCM] Call notification sent for callId=${callId}: ${response}`);
    return response;
  } catch (error) {
    logger.error(`[FCM] Call notification failed for callId=${callId}: ${error.message}`);
    return false;
  }
};

const sendCallEndedNotification = async (registrationToken, { callId }) => {
  if (!registrationToken) {
    logger.info("[FCM] Call-ended notification skipped: No registration token.");
    return false;
  }

  const message = {
    data: stringifyDataPayload({
      type: "call_ended",
      callId: String(callId),
    }),
    token: registrationToken,
    android: {
      priority: "high",
      ttl: 45000,
    },
    apns: {
      headers: {
        "apns-priority": "10",
        "apns-push-type": "background",
        "apns-expiration": "45",
      },
      payload: {
        aps: { "content-available": 1 },
      },
    },
  };

  try {
    const response = await getMessaging().send(message);
    logger.info(`[FCM] Call-ended notification sent for callId=${callId}: ${response}`);
    return response;
  } catch (error) {
    logger.error(`[FCM] Call-ended notification failed for callId=${callId}: ${error.message}`);
    return false;
  }
};

const sendLocationRequest = async (registrationToken) => {
  if (!registrationToken) {
    logger.info('[FCM] Location request skipped: No registration token.');
    return false;
  }

  const message = {
    data: stringifyDataPayload({ type: 'nearby_locate' }),
    token: registrationToken,
    android: {
      priority: 'high',
      ttl: 120000,
    },
    apns: {
      headers: {
        // Background pushes must be priority 5 — Apple rejects or throttles
        // content-available at 10, which is reserved for user-visible alerts.
        'apns-priority': '5',
        'apns-push-type': 'background',
        'apns-expiration': String(Math.floor(Date.now() / 1000) + 120),
      },
      payload: {
        // No alert, sound or badge: adding any of them would make this a
        // visible notification, which is not what was consented to.
        aps: { 'content-available': 1 },
      },
    },
  };

  try {
    return await getMessaging().send(message);
  } catch (error) {
    logger.error(`[FCM] Location request failed: ${error.message}`);
    return false;
  }
};

const verifyIdToken = async (idToken) => {
  if (!isInitialized) {
    throw new Error("Firebase Admin SDK is not initialized.");
  }
  return await getAuth().verifyIdToken(idToken);
};

const { getActiveDeviceTokens } = require("../modules/auth/deviceSessions");

const sendPushToUser = async (user, title, body, data = {}, excludeDeviceIds) => {
  const tokens = await getActiveDeviceTokens(user._id || user.id, excludeDeviceIds);
  return Promise.all(tokens.map((token) => sendPushNotification(token, title, body, data)));
};

const sendCallNotificationToUser = async (user, opts) => {
  const tokens = await getActiveDeviceTokens(user._id || user.id);
  return Promise.all(tokens.map((token) => sendCallNotification(token, opts)));
};

const sendCallEndedNotificationToUser = async (user, opts) => {
  const tokens = await getActiveDeviceTokens(user._id || user.id);
  return Promise.all(tokens.map((token) => sendCallEndedNotification(token, opts)));
};

/** Every device on the account is asked; the first to answer wins. */
const sendLocationRequestToUser = async (user) => {
  const tokens = await getActiveDeviceTokens(user._id || user.id);
  if (tokens.length === 0) return [];
  return Promise.all(tokens.map((token) => sendLocationRequest(token)));
};

// FCM's multicast call caps at 500 tokens per request.
const MULTICAST_CHUNK_SIZE = 500;

const sendMulticastNotification = async (tokens, title, body, data = {}) => {
  const uniqueTokens = Array.from(new Set(tokens)).filter(Boolean);
  if (uniqueTokens.length === 0) return { successCount: 0, failureCount: 0 };

  const message = {
    data: stringifyDataPayload({ ...data, title, body }),
    android: { priority: 'high' },
    apns: {
      headers: { 'apns-priority': '10' },
      payload: { aps: { alert: { title, body }, sound: 'default', badge: 1 } },
    },
  };

  let successCount = 0;
  let failureCount = 0;

  for (let i = 0; i < uniqueTokens.length; i += MULTICAST_CHUNK_SIZE) {
    const chunk = uniqueTokens.slice(i, i + MULTICAST_CHUNK_SIZE);
    try {
      const response = await getMessaging().sendEachForMulticast({ ...message, tokens: chunk });
      successCount += response.successCount;
      failureCount += response.failureCount;
    } catch (error) {
      logger.error(`[FCM] Multicast chunk failed: ${error.message}`);
      failureCount += chunk.length;
    }
  }

  return { successCount, failureCount };
};

module.exports = {
  initializeFirebase,
  sendPushNotification,
  sendCallNotification,
  sendCallEndedNotification,
  sendLocationRequest,
  sendPushToUser,
  sendCallNotificationToUser,
  sendCallEndedNotificationToUser,
  sendLocationRequestToUser,
  sendMulticastNotification,
  verifyIdToken,
};
