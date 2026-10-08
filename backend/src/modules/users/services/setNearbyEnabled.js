const User = require('../../../models/User');
const { forgetPeers } = require('./nearbyPeers');
const { forgetPosition } = require('./nearbyGeo');

const setNearbyEnabled = async (userId, enabled) => {
  const update = { nearbyEnabled: enabled };
  if (enabled) update.nearbyLastOn = new Date();

  const user = await User.findByIdAndUpdate(userId, update, { new: true })
    .select('nearbyEnabled nearbyLastOn')
    .lean();

  // The peers record goes too, not just the position. Leaving it behind would
  // let the user keep messaging people they were shown before they opted out.
  if (!enabled) {
    await Promise.all([forgetPeers(userId), forgetPosition(userId)]);
  }

  return { nearbyEnabled: !!user?.nearbyEnabled };
};

module.exports = setNearbyEnabled;
