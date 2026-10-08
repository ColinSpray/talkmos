const User = require('../models/User');
const logger = require('../utils/logger');

// Refreshed while a user is connected rather than only on disconnect: a worker
// that dies without firing its handlers still leaves a last-seen within one
// refresh of the truth instead of a value hours stale.
const REFRESH_MS = 120_000;

let lastRefreshAt = 0;

const stamp = async (userIds) => {
  // Filtered before stringifying: a null mapped first becomes "null", which
  // survives the filter and casts the whole $in batch into an error.
  const ids = [...new Set((userIds || []).filter(Boolean).map(String))];
  if (ids.length === 0) return 0;
  try {
    await User.updateMany(
      { _id: { $in: ids } },
      { $set: { lastSeenAt: new Date() } }
    );
    return ids.length;
  } catch (err) {
    logger.error(`[lastSeen] stamp failed: ${err.message}`);
    return 0;
  }
};

// Driven by the presence heartbeat, which ticks far more often than this needs
// to write.
const refresh = (userIds, now = Date.now()) => {
  if (now - lastRefreshAt < REFRESH_MS) return Promise.resolve(0);
  lastRefreshAt = now;
  return stamp(userIds);
};

// Test seam — the throttle is module state that would otherwise leak between cases.
const resetThrottle = () => {
  lastRefreshAt = 0;
};

module.exports = { stamp, refresh, resetThrottle, REFRESH_MS };
