const { str, num, bool } = require('../../utils/validators');

// Multipart text fields arrive as strings; num/bool coerce them.
const uploadApk = {
  body: {
    versionName: str({ max: 32 }),
    versionCode: num({ integer: true, min: 0 }),
    minRequiredVersionCode: num({ integer: true, min: 0 }),
    releaseNotes: str({ max: 5000 }),
    isForceUpdate: bool(),
  },
};

const getApkInfo = {
  query: {
    versionCode: num({ integer: true, min: 0 }),
    v: num({ integer: true, min: 0 }),
  },
};

module.exports = { uploadApk, getApkInfo };
