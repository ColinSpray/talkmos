const User = require('../../../models/User');
const { recordPosition } = require('./nearbyGeo');

const nearbyPing = async (userId, lat, lng) => {
  const user = await User.findById(userId).select('nearbyEnabled').lean();
  if (!user?.nearbyEnabled) {
    const err = new Error('Nearby is turned off for this account');
    err.status = 403;
    throw err;
  }

  await recordPosition(userId, Number(lat), Number(lng));
  return { recorded: true };
};

module.exports = nearbyPing;
