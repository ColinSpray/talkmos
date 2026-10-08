const User = require('../../../models/User');
const FriendRequest = require('../../../models/FriendRequest');
const logger = require('../../../utils/logger');
const { rememberPeers } = require('./nearbyPeers');
const { recordPosition, findNearbyPeers } = require('./nearbyGeo');
const { requestDeviceLocation } = require('./requestDeviceLocation');

const TIER_RIGHT_HERE = 'right_here';
const TIER_VERY_CLOSE = 'very_close';
const TIER_NEARBY = 'nearby';

const {
  TIER_RIGHT_HERE_M: RIGHT_HERE_M,
  TIER_VERY_CLOSE_M: VERY_CLOSE_M,
} = require('../../../config/nearby');

const tierFor = (distanceM) => {
  if (distanceM <= RIGHT_HERE_M) return TIER_RIGHT_HERE;
  if (distanceM <= VERY_CLOSE_M) return TIER_VERY_CLOSE;
  return TIER_NEARBY;
};

const TIER_ORDER = { [TIER_RIGHT_HERE]: 0, [TIER_VERY_CLOSE]: 1, [TIER_NEARBY]: 2 };

const nearbyHeartbeat = async ({ userId, lat, lng }) => {
  const me = await User.findById(userId).select('nearbyEnabled isBlocked').lean();
  if (!me) {
    const err = new Error('User not found');
    err.status = 404;
    throw err;
  }
  if (!me.nearbyEnabled) {
    const err = new Error('Nearby is turned off for this account');
    err.status = 403;
    throw err;
  }

  if (lat !== undefined && lng !== undefined) {
    await recordPosition(userId, Number(lat), Number(lng));
  }

  const peers = await findNearbyPeers(userId);
  if (peers.length === 0) return [];

  const distanceById = new Map(peers.map((p) => [String(p.id), p.distanceM]));
  const candidateIds = [...distanceById.keys()];

  await rememberPeers(userId, candidateIds);

  for (const id of candidateIds) {
    requestDeviceLocation(id).catch((error) =>
      logger.error(`[nearby] locate request failed for ${id}: ${error.message}`)
    );
  }

  const candidates = await User.find({ _id: { $in: candidateIds }, nearbyEnabled: true })
    .select('_id name username avatarUrl isVerified profilePhotoVisibility isBlocked')
    .lean();

  const iBlocked = new Set((me.isBlocked || []).map(String));
  const visible = candidates.filter(
    (u) => !iBlocked.has(String(u._id)) && !(u.isBlocked || []).some((id) => String(id) === String(userId))
  );
  if (visible.length === 0) return [];

  const ids = visible.map((u) => u._id);
  const related = await FriendRequest.find({
    $or: [
      { sender: userId, receiver: { $in: ids } },
      { sender: { $in: ids }, receiver: userId },
    ],
  })
    .select('sender receiver')
    .lean();

  const relatedIds = new Set(related.flatMap((r) => [String(r.sender), String(r.receiver)]));

  return visible
    .filter((u) => !relatedIds.has(String(u._id)))
    .map((u) => ({
      _id: u._id,
      name: u.name,
      username: u.username || '',
      avatarUrl: u.profilePhotoVisibility === 'Everyone' ? u.avatarUrl || '' : '',
      isVerified: !!u.isVerified,
      tier: tierFor(distanceById.get(String(u._id))),
    }))
    .sort((a, b) => TIER_ORDER[a.tier] - TIER_ORDER[b.tier]);
};

module.exports = nearbyHeartbeat;
