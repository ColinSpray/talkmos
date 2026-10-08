const CallParticipant = require('../../../models/CallParticipant');

/**
 * Records that a joined participant's socket went away, without ending
 * anything. A browser reload disconnects and reconnects within a second or
 * two; finalizing on the disconnect leaves nothing to come back to.
 *
 * Returns null when there was nothing to hold open — the user was not in the
 * call, or had already left it properly.
 */
const markDisconnected = async ({ callId, userId }) => {
  const disconnectedAt = new Date();
  const participant = await CallParticipant.findOneAndUpdate(
    { callId, userId, status: 'joined' },
    { $set: { disconnectedAt } },
    { new: true }
  );

  return participant ? { participant, disconnectedAt } : null;
};

module.exports = markDisconnected;
