const crypto = require('crypto');

const ALGORITHM = 'AWS4-HMAC-SHA256';
// A presigned PUT is signed before the bytes exist, so the payload hash cannot
// be computed. S3 and MinIO both accept this literal in its place.
const UNSIGNED_PAYLOAD = 'UNSIGNED-PAYLOAD';

const hmac = (key, value) => crypto.createHmac('sha256', key).update(value, 'utf8').digest();
const sha256Hex = (value) => crypto.createHash('sha256').update(value, 'utf8').digest('hex');

// RFC 3986. encodeURIComponent leaves !'()* alone, which S3 expects encoded —
// a name containing any of them signs one string and requests another.
const uriEncode = (value) =>
  encodeURIComponent(value).replace(/[!'()*]/g, (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`);

// Path segments are encoded individually so the separators survive. S3 (unlike
// most AWS services) does not encode the path a second time for the signature.
const encodePath = (path) => path.split('/').map(uriEncode).join('/');

const canonicalQuery = (params) =>
  Object.keys(params)
    .sort()
    .map((key) => `${uriEncode(key)}=${uriEncode(String(params[key]))}`)
    .join('&');

// YYYYMMDDTHHMMSSZ, the only timestamp format the signature accepts.
const amzDate = (date) => date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');

const signingKey = (secretKey, dateStamp, region, service) => {
  const kDate = hmac(`AWS4${secretKey}`, dateStamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, service);
  return hmac(kService, 'aws4_request');
};

/**
 * Builds a presigned URL carrying its own credentials in the query string.
 *
 * Only `host` is signed. Signing Content-Type as well would be stricter, but it
 * makes every upload fail whenever a client library normalises the header (a
 * charset suffix is enough), and the type is not a security boundary here.
 */
const presignUrl = ({
  method,
  endpoint,
  path,
  accessKeyId,
  secretAccessKey,
  region,
  service = 's3',
  expiresIn = 900,
  query = {},
  now = new Date(),
}) => {
  const url = new URL(endpoint);
  const timestamp = amzDate(now);
  const dateStamp = timestamp.slice(0, 8);
  const scope = `${dateStamp}/${region}/${service}/aws4_request`;

  // `url.host` keeps a non-default port, which has to be part of the signed
  // host header or MinIO on :9000 rejects every signature.
  const params = {
    ...query,
    'X-Amz-Algorithm': ALGORITHM,
    'X-Amz-Credential': `${accessKeyId}/${scope}`,
    'X-Amz-Date': timestamp,
    'X-Amz-Expires': String(expiresIn),
    'X-Amz-SignedHeaders': 'host',
  };

  const canonicalPath = encodePath(path.startsWith('/') ? path : `/${path}`);
  const canonicalRequest = [
    method,
    canonicalPath,
    canonicalQuery(params),
    `host:${url.host}\n`,
    'host',
    UNSIGNED_PAYLOAD,
  ].join('\n');

  const stringToSign = [ALGORITHM, timestamp, scope, sha256Hex(canonicalRequest)].join('\n');

  const signature = crypto
    .createHmac('sha256', signingKey(secretAccessKey, dateStamp, region, service))
    .update(stringToSign, 'utf8')
    .digest('hex');

  return `${url.origin}${canonicalPath}?${canonicalQuery(params)}&X-Amz-Signature=${signature}`;
};

module.exports = { presignUrl, uriEncode, encodePath };
