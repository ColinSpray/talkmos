const { str, bool, obj, email, phone, username, otpCode, url } = require('../../utils/validators');

const PLATFORMS = ['ios', 'android', 'web', 'other'];
const VISIBILITY = ['Everyone', 'Contacts', 'Nobody'];
const STATUSES = ['online', 'offline', 'away', 'busy'];

const PASSWORD = { min: 6, max: 128, trim: false };
const FCM_TOKEN = { min: 0, max: 4096 };

// Optional on every auth route — a client that omits it just gets a token
// with no device session attached.
const device = obj({
  shape: {
    deviceId: str({ required: true, max: 128 }),
    deviceName: str({ max: 128 }),
    platform: str({ values: PLATFORMS }),
    fcmToken: str(FCM_TOKEN),
  },
});

const register = {
  body: {
    name: str({ required: true, max: 80 }),
    email: email(),
    password: str({ required: true, ...PASSWORD }),
    device,
  },
};

const login = {
  body: {
    email: email(),
    username: str({ max: 30 }),
    password: str({ required: true, ...PASSWORD }),
    device,
  },
  check: (req) =>
    req.body.email || req.body.username ? null : 'Please provide email or username',
};

const googleLogin = {
  body: {
    idToken: str({ required: true, max: 4096, trim: false }),
    device,
  },
};

const sendPhoneOtp = {
  body: { phone: phone({ required: true }) },
};

const verifyPhoneOtp = {
  body: {
    phone: phone({ required: true }),
    code: otpCode({ required: true }),
    device,
  },
};

// Either identifier works, but one of them has to be a real value — an empty
// body used to build an unfiltered lookup.
const identifierCheck = (req) =>
  req.body.email || req.body.phone ? null : 'Please provide an email or phone number';

const forgotPassword = {
  body: {
    email: email(),
    phone: phone(),
  },
  check: identifierCheck,
};

const resetPassword = {
  body: {
    email: email(),
    phone: phone(),
    code: otpCode({ required: true }),
    password: str({ required: true, ...PASSWORD }),
  },
  check: identifierCheck,
};

const updateFcmToken = {
  body: { fcmToken: str({ required: true, ...FCM_TOKEN }) },
};

const updateProfile = {
  body: {
    name: str({ max: 80 }),
    username: username(),
    avatarUrl: url(),
    bio: str({ max: 500 }),
    location: str({ max: 120 }),
    status: str({ values: STATUSES }),
    phone: phone({ min: 0 }),
    notificationsEnabled: bool(),
    notificationPreviewEnabled: bool(),
    readReceiptsEnabled: bool(),
    lastSeenVisibility: str({ values: VISIBILITY }),
    profilePhotoVisibility: str({ values: VISIBILITY }),
    isPublic: bool(),
  },
};

module.exports = {
  register,
  login,
  googleLogin,
  sendPhoneOtp,
  verifyPhoneOtp,
  forgotPassword,
  resetPassword,
  updateFcmToken,
  updateProfile,
};
