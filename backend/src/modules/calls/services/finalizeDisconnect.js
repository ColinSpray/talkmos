const CallParticipant = require('../../../models/CallParticipant');
const leaveCall = require('./leaveCall');

/**
 * Ends the grace period opened by [markDisconnected], unless the participant
 * came back. `since` is the stamp that countdown was started for: a cleared
 * stamp means they rejoined, a newer one means they dropped again and that
 * later countdown owns the decision.
 *
 * Deliberately decided from the stored stamp rather than from the timer that
 * fired, so a rejoin handled by a different process still calls this one off.
 */
const finalizeDisconnect = async ({ callId, userId, since }) => {
  const participant = await CallParticipant.findOne({ callId, userId });
  if (!participant?.disconnectedAt) return null;
  if (since && participant.disconnectedAt.getTime() !== new Date(since).getTime()) {
    return null;
  }

  return leaveCall({ callId, userId });
};

module.exports = finalizeDisconnect;
