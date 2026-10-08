const express = require('express');
const router = express.Router();
const { protect } = require('../../middleware/authMiddleware');
const { rateLimiter } = require('../../middleware/rateLimit');
const { getMessageKey } = require('./keyController');

// Fetched once per launch and cached on the device, so a client asking far
// more often than that is either broken or fishing. Keyed on the account
// rather than the address: this sits behind auth, and one office wifi should
// not share a quota for it.
const keyLimiter = rateLimiter({
  points: 20,
  duration: 300,
  keyPrefix: 'rl:keys',
  key: (req) => String(req.user._id),
});

router.get('/message', protect, keyLimiter, getMessageKey);

module.exports = router;
