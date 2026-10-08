const express = require('express');
const router = express.Router();
const { uploadApk, downloadApk, getApkInfo } = require('./apkController');
const { protect, adminOnly } = require('../../middleware/authMiddleware');
const { validate } = require('../../middleware/validate');
const schema = require('./apkValidation');

router.get('/info', validate(schema.getApkInfo), getApkInfo);
router.get('/download', downloadApk);
router.post('/upload', protect, adminOnly, uploadApk);

module.exports = router;
