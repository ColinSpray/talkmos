const User = require('../../models/User');
const DeviceSession = require('../../models/DeviceSession');
const otpService = require('../../services/otpService');
const logger = require('../../utils/logger');
const fcmService = require('../../services/fcmService');
const notificationQueue = require('../../services/notificationQueue');
const userCache = require('../../services/userCache');
const { invalidateUserSessions } = require('../../services/deviceSessionCache');
const { generateToken, upsertDeviceSession, revokeDeviceSession } = require('./deviceSessions');

// 1. REGISTER
const register = async (req, res) => {
  try {
    const SystemSetting = require('../../models/SystemSetting');
    const settings = await SystemSetting.getSettings();
    if (!settings.allowNewRegistrations) {
      return res.status(403).json({ success: false, message: 'New user registrations are currently disabled by the administrator' });
    }

    const { name, email, password, device } = req.body;

    if (email) {
      const emailExists = await User.findOne({ email });
      if (emailExists) return res.status(400).json({ success: false, message: 'Email already registered' });
    }

    const user = await User.create({
      name,
      email: email || undefined,
      password,
    });

    const deviceSession = await upsertDeviceSession(user._id, device, req);

    const token = generateToken(user._id, deviceSession);

    return res.status(201).json({
      success: true,
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        isVerified: user.isVerified,
        isPremium: user.isPremium,
      },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. LOGIN
const login = async (req, res) => {
  try {
    const { email, username, password, device } = req.body;
    const query = email ? { email } : { username };

    const user = await User.findOne(query);
    if (!user || !(await user.matchPassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const deviceSession = await upsertDeviceSession(user._id, device, req);

    const token = generateToken(user._id, deviceSession);

    return res.json({
      success: true,
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        username: user.username,
        phone: user.phone,
        isVerified: user.isVerified,
        isPremium: user.isPremium,
      },
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const logout = async (req, res) => {
  try {
    if (req.deviceId) {
      await revokeDeviceSession(req.user.id, req.deviceId);
      const io = req.app.get('io');
      io?.disconnectUserDevice?.(String(req.user.id), req.deviceId);
    }
    return res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Lists the caller's known devices — active sessions plus recent
// logged-out history (bounded by MAX_DEVICE_SESSIONS), most recent first.
const getDevices = async (req, res) => {
  try {
    const sessions = await DeviceSession.find({ userId: req.user.id })
      .sort({ lastActiveAt: -1 })
      .lean();

    const devices = sessions.map((d) => ({
      deviceId: d.deviceId,
      deviceName: d.deviceName,
      platform: d.platform,
      isActive: d.isActive,
      isCurrent: d.deviceId === req.deviceId,
      loginAt: d.loginAt,
      lastActiveAt: d.lastActiveAt,
      loggedOutAt: d.loggedOutAt,
    }));

    return res.json({ success: true, data: devices });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const revokeDevice = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const revoked = await revokeDeviceSession(req.user.id, deviceId);
    if (!revoked) return res.status(404).json({ success: false, message: 'Device not found' });

    const io = req.app.get('io');
    io?.disconnectUserDevice?.(String(req.user.id), deviceId);

    return res.json({ success: true, message: 'Device logged out' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 4. FORGOT & RESET PASSWORD
const forgotPassword = async (req, res) => {
  try {
    const { email, phone } = req.body;
    const user = await User.findOne(email ? { email } : { phone });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const destination = phone || email;
    const { code } = await otpService.createOtp(destination);

    if (phone) {
      await notificationQueue.publishSMS({ to: phone, message: `Your Talkmos password reset code is ${code}. It expires in 10 minutes.` });
    } else {
      await notificationQueue.publishMail({
        to: email,
        subject: 'Reset your Talkmos password',
        body: `Your password reset code is ${code}. It expires in 10 minutes.`,
      });
    }

    return res.json({
      success: true,
      message: 'Password reset code generated successfully',
      ...(phone && process.env.OTP_AUTOFILL === 'true' ? { devCode: code } : {}),
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const resetPassword = async (req, res) => {
  try {
    const { email, phone, code, password } = req.body;

    const destination = phone || email;
    const record = await otpService.verifyOtp(destination, code);
    if (!record) {
      return res.status(400).json({ success: false, message: 'Invalid or expired recovery code' });
    }

    const user = await User.findOne(email ? { email } : { phone });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    user.password = password;
    await user.save();
    await userCache.invalidateUser(user._id);

    await otpService.markOtpUsed(phone || email);

    return res.json({ success: true, message: 'Password reset successfully' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 5. PROFILE
const getProfile = async (req, res) => {
  try {
    const user = await userCache.getUser(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    return res.json({
      success: true,
      data: user
    });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;

    if (!req.deviceId) {
      return res.status(400).json({
        success: false,
        message: 'This session has no device attached — please sign in again',
      });
    }

    const updated = await DeviceSession.updateOne(
      { userId: req.user.id, deviceId: req.deviceId },
      { $set: { fcmToken } }
    );
    if (updated.matchedCount === 0) {
      return res.status(404).json({ success: false, message: 'Device session not found' });
    }
    await invalidateUserSessions(req.user.id, req.deviceId);

    return res.json({ success: true, message: 'FCM Token updated successfully' });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 6. GOOGLE LOGIN VIA FIREBASE / OAUTH
const googleLogin = async (req, res) => {
  try {
    // Identity comes from the signed token only. An email in the request body
    // is attacker-controlled and is never accepted as proof of who the caller is.
    const { idToken, device } = req.body;

    let email, name, picture;
    try {
      const decodedToken = await fcmService.verifyIdToken(idToken);
      email = decodedToken.email;
      name = decodedToken.name;
      picture = decodedToken.picture;
    } catch (tokenErr) {
      logger.warn(`Firebase verifyIdToken error: ${tokenErr.message}`);
      return res.status(400).json({ success: false, message: `Token verification failed: ${tokenErr.message}` });
    }

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email address is required for Google login' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    let user = await User.findOne({ email: normalizedEmail });
    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      const SystemSetting = require('../../models/SystemSetting');
      const settings = await SystemSetting.getSettings();
      if (!settings.allowNewRegistrations) {
        return res.status(403).json({ success: false, message: 'New user registrations are currently disabled by the administrator' });
      }

      user = new User({
        name: name || normalizedEmail.split('@')[0],
        email: normalizedEmail,
        avatarUrl: picture || '',
        authProvider: 'google',
        isVerified: true,
      });
    } else {
      if (!user.avatarUrl && picture) {
        user.avatarUrl = picture;
      }
      if (user.authProvider === 'local') {
        user.authProvider = 'google';
      }
      user.isVerified = true;
    }

    await user.save();
    await userCache.invalidateUser(user._id);

    const deviceSession = await upsertDeviceSession(user._id, device, req);

    const jwtToken = generateToken(user._id, deviceSession);

    return res.status(200).json({
      success: true,
      token: jwtToken,
      isNewUser: isNewUser && (!user.phone || user.phone.trim() === ''),
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        username: user.username || '',
        phone: user.phone || '',
        isVerified: user.isVerified,
        isPremium: user.isPremium,
        avatarUrl: user.avatarUrl,
      },
    });
  } catch (error) {
    logger.error(`googleLogin error: ${error.message}`);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const {
      name, username, avatarUrl, bio, location, status, phone,
      notificationsEnabled, notificationPreviewEnabled,
      readReceiptsEnabled, lastSeenVisibility, profilePhotoVisibility,
      isPublic,
    } = req.body;

    const updateFields = {};
    if (name !== undefined) updateFields.name = name;
    if (phone !== undefined) {
      if (phone) {
        const phoneTaken = await User.findOne({ phone, _id: { $ne: req.user.id } });
        if (phoneTaken) {
          return res.status(409).json({
            success: false,
            code: 'PHONE_ALREADY_LINKED',
            message: 'This phone number is already linked to another account. Log out and sign in with your phone number to access it.',
          });
        }
      }
      updateFields.phone = phone;
    }
    if (username !== undefined) {
      const taken = await User.findOne({ username, _id: { $ne: req.user.id } });
      if (taken) return res.status(400).json({ success: false, message: 'Username already taken' });
      updateFields.username = username;
    }
    if (avatarUrl !== undefined) updateFields.avatarUrl = avatarUrl;
    if (bio !== undefined) updateFields.bio = bio;
    if (location !== undefined) updateFields.location = location;
    if (status !== undefined) updateFields.status = status;

    if (notificationsEnabled !== undefined) updateFields.notificationsEnabled = !!notificationsEnabled;
    if (notificationPreviewEnabled !== undefined) updateFields.notificationPreviewEnabled = !!notificationPreviewEnabled;
    if (readReceiptsEnabled !== undefined) updateFields.readReceiptsEnabled = !!readReceiptsEnabled;

    if (isPublic !== undefined) updateFields.isPublic = !!isPublic;

    if (lastSeenVisibility !== undefined) updateFields.lastSeenVisibility = lastSeenVisibility;
    if (profilePhotoVisibility !== undefined) updateFields.profilePhotoVisibility = profilePhotoVisibility;

    const user = await User.findByIdAndUpdate(req.user.id, { $set: updateFields }, { new: true }).select('-password');
    await userCache.invalidateUser(req.user.id);
    return res.json({ success: true, data: user });
  } catch (error) {
    logger.error(error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ─── PHONE / OTP AUTH ────────────────────────────────────────────────────────

// Send a one-time code to a phone number to start login/registration.
const sendPhoneOtp = async (req, res) => {
  try {
    const { phone } = req.body;
    const { code } = await otpService.createOtp(phone);
    await notificationQueue.publishSMS({ to: phone, message: `Your Talkmos verification code is ${code}. It expires in 10 minutes.` });

    return res.json({
      success: true,
      message: 'Verification code sent',
      ...(process.env.OTP_AUTOFILL === 'true' ? { devCode: code } : {}),
    });
  } catch (error) {
    logger.error(`sendPhoneOtp error: ${error.message}`);
    return res.status(400).json({ success: false, message: error.message });
  }
};

// Verify the code. Logs the user in (creating a phone account on first use) and
// reports whether they still need to complete their profile (name/username).
const verifyPhoneOtp = async (req, res) => {
  try {
    const { phone, code, device } = req.body;

    const record = await otpService.verifyOtp(phone, code);
    if (!record) {
      return res.status(400).json({ success: false, message: 'Invalid or expired code' });
    }
    await otpService.markOtpUsed(phone);

    let user = await User.findOne({ phone });
    let isNewUser = false;
    if (!user) {
      user = await User.create({ phone, authProvider: 'phone' });
      isNewUser = true;
    } else if (!user.username || !user.name) {
      // Existing account that never finished onboarding.
      isNewUser = true;
    }

    const deviceSession = await upsertDeviceSession(user._id, device, req);

    const token = generateToken(user._id, deviceSession);
    return res.json({
      success: true,
      isNewUser,
      token,
      user: {
        _id: user._id,
        name: user.name || '',
        username: user.username || '',
        phone: user.phone,
        email: user.email || '',
        avatarUrl: user.avatarUrl || '',
        isVerified: user.isVerified,
        isPremium: user.isPremium,
      },
    });
  } catch (error) {
    logger.error(`verifyPhoneOtp error: ${error.message}`);
    return res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = { register, login, logout, forgotPassword, resetPassword, getProfile, updateFcmToken, googleLogin, updateProfile, sendPhoneOtp, verifyPhoneOtp, getDevices, revokeDevice };
