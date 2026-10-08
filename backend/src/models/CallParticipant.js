const mongoose = require('mongoose');

const CallParticipantSchema = new mongoose.Schema(
  {
    callId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Call',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    status: {
      type: String,
      enum: [
        'invited',   // added to the call but hasn't responded yet
        'ringing',   // actively being notified
        'joined',    // currently connected
        'declined',  // explicitly rejected the call
        'missed',    // never responded before the call ended
        'left',      // joined, then disconnected/hung up
        'busy',      // was already on another call
      ],
      default: 'invited',
    },
    // When this participant's socket dropped while still joined. A reload
    // clears it on rejoin; a countdown that finds it still set is the one that
    // finalizes the leave. See scheduleLeaveOnDisconnect.
    disconnectedAt: {
      type: Date,
      default: null,
    },
    joinedAt: {
      type: Date,
      default: null,
    },
    leftAt: {
      type: Date,
      default: null,
    },
    // Media state when they left (useful for call-summary UI / debugging)
    wasMuted: {
      type: Boolean,
      default: false,
    },
    wasVideoOff: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

CallParticipantSchema.index({ callId: 1, userId: 1 }, { unique: true });
// leaveCall's "is anyone still on the call" / "any invites outstanding" counts.
CallParticipantSchema.index({ callId: 1, status: 1 });
CallParticipantSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('CallParticipant', CallParticipantSchema);
