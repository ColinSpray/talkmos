const { getClient } = require('../../../config/redis');
const { PRESENCE_TTL_SECONDS } = require('./nearbyGeo');

const PEERS_TTL_SECONDS = PRESENCE_TTL_SECONDS;

const peersKey = (userId) => `nearby:peers:${userId}`;

const rememberPeers = async (userId, peerIds) => {
  if (!peerIds || peerIds.length === 0) return;
  await getClient()
    .multi()
    .sadd(peersKey(userId), ...peerIds.map(String))
    .expire(peersKey(userId), PEERS_TTL_SECONDS)
    .exec();
};

const hasSeenPeer = async (userId, peerId) =>
  (await getClient().sismember(peersKey(userId), String(peerId))) === 1;

/** Drops the record the moment the user stops being discoverable. */
const forgetPeers = async (userId) => {
  await getClient().del(peersKey(userId));
};

module.exports = {
  PEERS_TTL_SECONDS,
  rememberPeers,
  hasSeenPeer,
  forgetPeers,
};
