const { getClient } = require('../../../config/redis');
const User = require('../../../models/User');

const {
  PRESENCE_TTL_SECONDS,
  GRID_DECIMALS,
  DEFAULT_RADIUS_M,
  MAX_RADIUS_M,
  MAX_RESULTS,
  LAST_KNOWN_MAX_AGE_SECONDS,
} = require('../../../config/nearby');

const GEO_KEY = 'nearby:geo';
const SEEN_KEY = 'nearby:seen';

const snap = (n) => Math.round(n * 10 ** GRID_DECIMALS) / 10 ** GRID_DECIMALS;

const isValidCoord = (lat, lng) =>
  Number.isFinite(lat) && Number.isFinite(lng) &&
  lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 &&
  // 0,0 is in the Atlantic and is what a broken location provider reports.
  // Accepting it would collect every failing device into one phantom crowd.
  !(lat === 0 && lng === 0);

const recordPosition = async (userId, lat, lng) => {
  if (!isValidCoord(lat, lng)) {
    const err = new Error('Invalid coordinates');
    err.status = 400;
    throw err;
  }

  const [snappedLat, snappedLng] = [snap(lat), snap(lng)];

  await Promise.all([
    getClient()
      .multi()
      .geoadd(GEO_KEY, snappedLng, snappedLat, String(userId))
      .zadd(SEEN_KEY, Math.floor(Date.now() / 1000), String(userId))
      .exec(),
    User.updateOne(
      { _id: userId },
      { $set: { lastKnownLocation: { lat: snappedLat, lng: snappedLng, at: new Date() } } }
    ).exec(),
  ]);
};

const seedPositionFromLastKnown = async (userId, maxAgeSeconds = LAST_KNOWN_MAX_AGE_SECONDS) => {
  const user = await User.findById(userId).select('lastKnownLocation').lean();
  const last = user?.lastKnownLocation;
  if (!last || !isValidCoord(last.lat, last.lng) || !last.at) return false;

  const ageSeconds = (Date.now() - new Date(last.at).getTime()) / 1000;
  if (ageSeconds > maxAgeSeconds) return false;

  await getClient()
    .multi()
    .geoadd(GEO_KEY, last.lng, last.lat, String(userId))
    .zadd(SEEN_KEY, Math.floor(new Date(last.at).getTime() / 1000), String(userId))
    .exec();

  return true;
};

const findNearbyPeers = async (userId, radiusM = DEFAULT_RADIUS_M) => {
  const radius = Math.min(Math.max(Number(radiusM) || DEFAULT_RADIUS_M, 1), MAX_RADIUS_M);

  let results;
  try {
    results = await getClient().geosearch(
      GEO_KEY,
      'FROMMEMBER',
      String(userId),
      'BYRADIUS',
      radius,
      'm',
      'ASC',
      'COUNT',
      MAX_RESULTS + 1,
      'WITHDIST'
    );
  } catch {
    // FROMMEMBER errors when the caller has no position of their own yet,
    // which is the normal state for someone who just opted in.
    return [];
  }

  // WITHDIST turns each entry into [member, distance] instead of a bare id.
  const candidates = results
    .map(([id, distance]) => ({ id, distanceM: Number(distance) }))
    .filter(({ id }) => id !== String(userId))
    .slice(0, MAX_RESULTS);
  if (candidates.length === 0) return [];

  const cutoff = Math.floor(Date.now() / 1000) - PRESENCE_TTL_SECONDS;
  const scores = await getClient().zmscore(SEEN_KEY, ...candidates.map((c) => c.id));

  return candidates.filter((_, i) => scores[i] !== null && Number(scores[i]) >= cutoff);
};

const forgetPosition = async (userId) => {
  await Promise.all([
    getClient().multi().zrem(GEO_KEY, String(userId)).zrem(SEEN_KEY, String(userId)).exec(),
    User.updateOne(
      { _id: userId },
      { $set: { lastKnownLocation: { lat: null, lng: null, at: null } } }
    ).exec(),
  ]);
};

const PRUNE_BATCH = 1000;

const prunePositions = async () => {
  const redis = getClient();
  const cutoff = Math.floor(Date.now() / 1000) - PRESENCE_TTL_SECONDS;
  const stale = await redis.zrangebyscore(SEEN_KEY, '-inf', cutoff);
  if (stale.length === 0) return 0;

  for (let i = 0; i < stale.length; i += PRUNE_BATCH) {
    const batch = stale.slice(i, i + PRUNE_BATCH);
    await redis.multi().zrem(GEO_KEY, ...batch).zrem(SEEN_KEY, ...batch).exec();
  }
  return stale.length;
};

module.exports = {
  PRESENCE_TTL_SECONDS,
  DEFAULT_RADIUS_M,
  LAST_KNOWN_MAX_AGE_SECONDS,
  snap,
  recordPosition,
  seedPositionFromLastKnown,
  findNearbyPeers,
  forgetPosition,
  prunePositions,
};
