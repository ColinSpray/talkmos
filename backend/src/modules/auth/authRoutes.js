const express = require('express');
const router = express.Router();
const { register, login, logout, forgotPassword, resetPassword, getProfile, updateFcmToken, googleLogin, updateProfile, sendPhoneOtp, verifyPhoneOtp, getDevices, revokeDevice } = require('./authController');
const { protect } = require('../../middleware/authMiddleware');
const { rateLimiter } = require('../../middleware/rateLimit');
const { validate, stringParam } = require('../../middleware/validate');
const schema = require('./authValidation');

const authLimiter = rateLimiter({ points: 10, duration: 60, keyPrefix: 'rl:auth' });
const otpSendLimiter = rateLimiter({ points: 5, duration: 900, keyPrefix: 'rl:otp-send' });
const otpVerifyLimiter = rateLimiter({ points: 10, duration: 900, keyPrefix: 'rl:otp-verify' });

router.param('deviceId', stringParam('deviceId', { max: 128 }));

router.get('/', protect, getProfile);
router.post('/register', authLimiter, validate(schema.register), register);
router.post('/login', authLimiter, validate(schema.login), login);
router.post('/google', authLimiter, validate(schema.googleLogin), googleLogin);
router.post('/phone/send-otp', otpSendLimiter, validate(schema.sendPhoneOtp), sendPhoneOtp);
router.post('/phone/verify-otp', otpVerifyLimiter, validate(schema.verifyPhoneOtp), verifyPhoneOtp);
router.post('/logout', protect, logout);
router.post('/forgot-password', otpSendLimiter, validate(schema.forgotPassword), forgotPassword);
router.post('/reset-password', otpVerifyLimiter, validate(schema.resetPassword), resetPassword);
router.put('/fcm-token', protect, validate(schema.updateFcmToken), updateFcmToken);
router.patch('/', protect, validate(schema.updateProfile), updateProfile);
router.get('/devices', protect, getDevices);
router.delete('/devices/:deviceId', protect, revokeDevice);

module.exports = router;
