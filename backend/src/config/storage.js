const str = (name, fallback) => {
  const raw = process.env[name];
  return raw === undefined || raw === '' ? fallback : raw;
};

const num = (name, fallback) => {
  const raw = process.env[name];
  if (raw === undefined || raw === '') return fallback;
  const parsed = Number(raw);
  if (!Number.isFinite(parsed)) {
    throw new Error(`[config] ${name} must be a number, got "${raw}"`);
  }
  return parsed;
};

// Trailing slashes would double up in every key path.
const trimSlash = (value) => (value ? value.replace(/\/+$/, '') : value);

const config = () => {
  // Signed against the host the *client* connects to: the signature covers the
  // host header, so signing an internal address and uploading to a public one
  // fails every time.
  const endpoint = trimSlash(str('MINIO_ENDPOINT', 'http://minio:9000'));

  return {
    endpoint,
    // Reads may go through a CDN or nginx vhost that never signs anything.
    // MEDIA_BASE_IMAGE_URL is accepted as an alias so an existing media-service
    // env block drops in unchanged.
    publicUrl: trimSlash(str('MINIO_PUBLIC_URL', str('MEDIA_BASE_IMAGE_URL', endpoint))),
    bucket: str('MINIO_BUCKET', ''),
    // Not a deployment setting: SigV4 bakes a region into the credential
    // scope it signs, so *something* has to go there. Self-hosted MinIO does
    // not check it (verified: any string, including an empty one, is
    // accepted). Override only for real S3, or a MinIO started with
    // MINIO_SITE_REGION set — those do enforce a match.
    region: str('MINIO_REGION', 'us-east-1'),
    accessKey: str('MINIO_ACCESS_KEY', ''),
    secretKey: str('MINIO_SECRET_KEY', ''),
    keyPrefix: trimSlash(str('MINIO_KEY_PREFIX', 'media')),
    uploadExpirySeconds: num('MINIO_UPLOAD_EXPIRY_SECONDS', 900),
  };
};

module.exports = { config };
