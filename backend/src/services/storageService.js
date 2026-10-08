const crypto = require('crypto');
const { presignUrl, encodePath } = require('../utils/awsSignature');
const { config } = require('../config/storage');

/**
 * Direct-to-storage uploads against a self-hosted MinIO (S3-compatible).
 *
 * The file never passes through this API: the client is handed a presigned
 * PUT it uploads to itself, and the read URL it should store on the message.
 * Read URLs are permanent and unsigned — the bucket serves objects publicly,
 * because a signed read URL would expire while the message it belongs to
 * stays in the history forever.
 */

const MAX_NAME_LENGTH = 80;
const EXTENSION_RE = /^\.[a-zA-Z0-9]{1,10}$/;

const two = (n) => String(n).padStart(2, '0');

// Object keys end up inside URLs that get logged, shared and pasted, so the
// caller's name is reduced to a predictable slug rather than percent-encoded.
const safeName = (fileName) => {
  const extMatch = fileName.match(/\.[^/.]+$/);
  const ext = extMatch && EXTENSION_RE.test(extMatch[0]) ? extMatch[0].toLowerCase() : '';
  const base = extMatch ? fileName.slice(0, -extMatch[0].length) : fileName;

  const slug = base
    .normalize('NFKD')
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    // Collapsed before the dashes are: a dotted run is what turns "a/../b"
    // into a key containing "..", which reads as traversal to anything that
    // later parses this path even though the separators are long gone.
    .replace(/\.{2,}/g, '-')
    .replace(/-{2,}/g, '-')
    .slice(0, MAX_NAME_LENGTH)
    .replace(/^[-.]+|[-.]+$/g, '');

  return `${slug || 'file'}${ext}`;
};

// Date-partitioned so the bucket stays navigable, and prefixed with random
// bytes so two people uploading "IMG_0001.jpg" never collide.
const objectKey = (fileName, prefix, now = new Date()) => {
  const rand = crypto.randomBytes(8).toString('hex');
  const datePath = `${now.getUTCFullYear()}/${two(now.getUTCMonth() + 1)}`;
  return [prefix, datePath, `${rand}_${safeName(fileName)}`].filter(Boolean).join('/');
};

const assertConfigured = (settings) => {
  if (settings.accessKey && settings.secretKey && settings.bucket) return settings;
  // Reported like the message-key route does: a deployment problem the client
  // can neither fix nor retry into, so it must not read as a client error.
  const err = new Error('Media storage is not configured on this server');
  err.statusCode = 503;
  throw err;
};

const getUploadParameters = async ({ fileName, mimeType }) => {
  const settings = assertConfigured(config());
  const key = objectKey(fileName, settings.keyPrefix);
  const path = `/${settings.bucket}/${key}`;

  const uploadUrl = presignUrl({
    method: 'PUT',
    endpoint: settings.endpoint,
    path,
    accessKeyId: settings.accessKey,
    secretAccessKey: settings.secretKey,
    region: settings.region,
    expiresIn: settings.uploadExpirySeconds,
  });

  return {
    uploadUrl,
    method: 'PUT',
    // Kept for the client contract — the Cloudinary flow needed form fields,
    // a presigned PUT carries everything in the URL.
    fields: {},
    headers: { 'Content-Type': mimeType },
    mediaUrl: `${settings.publicUrl}${encodePath(path)}`,
    expiresIn: settings.uploadExpirySeconds,
  };
};

module.exports = {
  getUploadParameters,
  objectKey,
  safeName,
};
