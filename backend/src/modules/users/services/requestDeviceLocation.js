const User = require('../../../models/User');
const logger = require('../../../utils/logger');
const { getClient } = require('../../../config/redis');
const { sendLocationRequestToUser } = require('../../../services/fcmService');
const { seedPositionFromLastKnown } = require('./nearbyGeo');

const { LOCATE_COOLDOWN_SECONDS: REQUEST_COOLDOWN_SECONDS } = require('../../../config/nearby');

const cooldownKey = (userId) => `nearby:locate:${userId}`;

const claimCooldown = async (userId) => {
  const claimed = await getClient().set(
    cooldownKey(userId),
    '1',
    'EX',
    REQUEST_COOLDOWN_SECONDS,
    'NX'
  );
  return claimed === 'OK';
};

const requestDeviceLocation = async (userId) => {
  if (!(await claimCooldown(userId))) return { pushed: false, seeded: false };

  const user = await User.findById(userId).select('nearbyEnabled').lean();
  if (!user?.nearbyEnabled) return { pushed: false, seeded: false };

  // Applied before the push and independently of whether it lands, so a user
  // whose device never answers is still covered.
  let seeded = false;
  try {
    seeded = await seedPositionFromLastKnown(userId);
  } catch (error) {
    logger.error(`[nearby] seed from last known failed for ${userId}: ${error.message}`);
  }

  try {
    const results = await sendLocationRequestToUser({ _id: userId });
    return { pushed: results.some(Boolean), seeded };
  } catch (error) {
    logger.error(`[nearby] location request failed for ${userId}: ${error.message}`);
    return { pushed: false, seeded };
  }
};

module.exports = {
  REQUEST_COOLDOWN_SECONDS,
  requestDeviceLocation,
};
