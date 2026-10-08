const multer = require('multer');
const path = require('path');
const fs = require('fs');
const SystemSetting = require('../../models/SystemSetting');
const { validate } = require('../../middleware/validate');
const apkValidation = require('./apkValidation');

const uploadDir = path.join(__dirname, '../../../uploads/apk');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => cb(null, 'talkmos.apk'),
});

const MAX_APK_BYTES = 500 * 1024 * 1024;

const upload = multer({
  storage,
  limits: { fileSize: MAX_APK_BYTES, files: 1 },
  fileFilter: (req, file, cb) => {
    if (
      file.mimetype === 'application/vnd.android.package-archive' ||
      file.originalname.endsWith('.apk')
    ) {
      cb(null, true);
    } else {
      cb(new Error('Only APK files allowed'));
    }
  },
});

// Multer rejections are client mistakes (wrong type, too large), not server
// faults — left alone they reach the global handler as a 500.
const receiveApk = (req, res, next) =>
  upload.single('apk')(req, res, (err) => {
    if (!err) return next();
    const message = err.code === 'LIMIT_FILE_SIZE'
      ? `APK must be ${Math.floor(MAX_APK_BYTES / (1024 * 1024))} MB or smaller`
      : err.message;
    return res.status(400).json({ success: false, message });
  });

const uploadApk = [
  receiveApk,
  validate(apkValidation.uploadApk),
  async (req, res) => {
    try {
      if (!req.file) {
        return res
          .status(400)
          .json({ success: false, message: 'No APK file uploaded' });
      }

      const {
        versionName,
        versionCode,
        minRequiredVersionCode,
        releaseNotes,
        isForceUpdate,
      } = req.body;

      const settings = await SystemSetting.getSettings();
      const updateFields = {};

      if (versionName !== undefined) updateFields.latestVersionName = versionName;
      if (versionCode !== undefined) updateFields.latestVersionCode = versionCode;
      if (minRequiredVersionCode !== undefined) {
        updateFields.minRequiredVersionCode = minRequiredVersionCode;
      }
      if (releaseNotes !== undefined) updateFields.releaseNotes = releaseNotes;
      if (isForceUpdate !== undefined) updateFields.isForceUpdate = isForceUpdate;

      const updatedSettings = await SystemSetting.findByIdAndUpdate(
        settings._id,
        { $set: updateFields },
        { new: true }
      );
      await SystemSetting.invalidateCache();

      const protocol = req.headers['x-forwarded-proto'] || req.protocol;
      return res.json({
        success: true,
        message: 'APK uploaded & version updated successfully',
        data: {
          versionName: updatedSettings.latestVersionName,
          versionCode: updatedSettings.latestVersionCode,
          minRequiredVersionCode: updatedSettings.minRequiredVersionCode,
          releaseNotes: updatedSettings.releaseNotes,
          isForceUpdate: updatedSettings.isForceUpdate,
          downloadUrl: `${protocol}://${req.get('host')}/api/v1/apk/download`,
        },
      });
    } catch (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
  },
];

const downloadApk = (req, res) => {
  const filePath = path.join(__dirname, '../../../uploads/apk/talkmos.apk');
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ success: false, message: 'APK not found' });
  }
  res.setHeader('Content-Type', 'application/vnd.android.package-archive');
  res.download(filePath, 'talkmos.apk');
};

const getApkInfo = async (req, res) => {
  try {
    const filePath = path.join(__dirname, '../../../uploads/apk/talkmos.apk');
    const available = fs.existsSync(filePath);

    const settings = await SystemSetting.getSettings();
    const reqVersionCode = req.query.versionCode ?? req.query.v ?? 1;

    const latestVersionCode = settings.latestVersionCode || 1;
    const minRequiredVersionCode = settings.minRequiredVersionCode || 1;

    const hasUpdate = available && latestVersionCode > reqVersionCode;
    const isForceUpdate =
      settings.isForceUpdate || reqVersionCode < minRequiredVersionCode;

    let fileSize = 0;
    let updatedAt = new Date();
    if (available) {
      const stats = fs.statSync(filePath);
      fileSize = stats.size;
      updatedAt = stats.mtime;
    }

    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const downloadUrl = `${protocol}://${req.get('host')}/api/v1/apk/download`;

    return res.json({
      success: true,
      available,
      hasUpdate,
      latestVersionName: settings.latestVersionName || '1.0.0',
      latestVersionCode,
      minRequiredVersionCode,
      isForceUpdate,
      releaseNotes:
        settings.releaseNotes || 'Bug fixes and performance improvements.',
      downloadUrl,
      fileSize,
      updatedAt,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { uploadApk, downloadApk, getApkInfo };
