const { getClient } = require('../config/redis');
const logger = require('../utils/logger');

const OTP_EXPIRY_SECONDS = 600; // 10 minutes

const _normalizeDestination = (destination) => {
  if (!destination) return null;
  return destination.toString().trim().toLowerCase();
};

const _generateCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const _key = (normalized) => `otp:${normalized}`;

const createOtp = async (destination) => {
  const normalized = _normalizeDestination(destination);
  if (!normalized) {
    throw new Error('Invalid OTP destination');
  }

  const otpCode = _generateCode();
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_SECONDS * 1000);

  // Plain SET overwrites any previous code for this destination and its
  // TTL, same as the old findOneAndUpdate({upsert:true}) did.
  await getClient().set(
    _key(normalized),
    JSON.stringify({ otp: otpCode, used: false }),
    'EX', OTP_EXPIRY_SECONDS
  );

  logger.info(`[OTP SERVICE] OTP created for ${normalized}`);
  return { code: otpCode, expiresAt };
};

const verifyOtp = async (destination, code) => {
  const normalized = _normalizeDestination(destination);
  if (!normalized || !code) {
    return null;
  }

  const raw = await getClient().get(_key(normalized));
  if (!raw) return null; // missing = never existed, or Redis already expired it

  const record = JSON.parse(raw);
  if (record.used) return null;
  if (record.otp !== code) return null;

  return record;
};

const markOtpUsed = async (destination) => {
  const normalized = _normalizeDestination(destination);
  if (!normalized) return null;

  const client = getClient();
  const key = _key(normalized);

  const raw = await client.get(key);
  if (!raw) return null;

  const record = JSON.parse(raw);
  if (record.used) return null; // already used — matches the old findOneAndUpdate({used:false}) guard

  record.used = true;

  const remainingTtl = await client.ttl(key);
  if (remainingTtl <= 0) return null; // expired between the GET above and here

  await client.set(key, JSON.stringify(record), 'EX', remainingTtl);

  return record;
};

module.exports = {
  createOtp,
  verifyOtp,
  markOtpUsed,
};
