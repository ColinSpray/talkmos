const { AccessToken } = require('livekit-server-sdk');

const createLivekitToken = async ({ room, identity, name, ttlSeconds = 3600 }) => {
  const apiKey = process.env.LIVEKIT_API_KEY;
  const apiSecret = process.env.LIVEKIT_API_SECRET;
  if (!apiKey || !apiSecret) {
    throw new Error('LiveKit is not configured (LIVEKIT_API_KEY / LIVEKIT_API_SECRET)');
  }
  if (!room) throw new Error('room is required');
  if (!identity) throw new Error('identity is required');

  const at = new AccessToken(apiKey, apiSecret, {
    identity: String(identity),
    name: name ? String(name) : String(identity),
    ttl: ttlSeconds,
  });
  at.addGrant({
    roomJoin: true,
    room: String(room),
    canPublish: true,
    canSubscribe: true,
  });

  // toJwt() is async in livekit-server-sdk v2.
  return at.toJwt();
};

module.exports = { createLivekitToken };
