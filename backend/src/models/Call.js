const mongoose = require('mongoose');

const CallSchema = new mongoose.Schema(
  {
    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Chat',
      required: true,
    },
    initiatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    callType: {
      type: String,
      enum: ['audio', 'video'],
      required: true,
    },
    isGroupCall: {
      type: Boolean,
      default: false,
    },
    status: {
      type: String,
      enum: [
        'ringing',   // created, waiting for callee(s) to join
        'ongoing',   // at least one participant has joined
        'ended',     // completed normally
        'missed',    // no callee ever joined
        'declined',  // callee explicitly rejected before joining
        'failed',    // technical failure (connection issue, provider error, etc.)
      ],
      default: 'ringing',
    },
    roomId: {
      type: String,
      required: true,
      unique: true,
    },
    startedAt: {
      type: Date,
      default: Date.now,
    },
    // When the call actually connected — the moment a second participant
    // joined. Null on one nobody ever answered, and what `duration` counts
    // from: `startedAt` includes however long the callee's phone rang.
    connectedAt: {
      type: Date,
      default: null,
    },
    endedAt: {
      type: Date,
      default: null,
    },
    endedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    duration: {
      type: Number,
      default: 0,
    },
    recordingUrl: {
      type: String,
      default: '',
    },
    createdAt: {
      type: Date,
      default: Date.now
    },
  },
);

// Call history for a chat, most recent first. Also serves plain {chatId}
// lookups via its prefix, so no separate single-field chatId index.
CallSchema.index({ chatId: 1, createdAt: -1 });
// "Calls I've made" history
CallSchema.index({ initiatedBy: 1, createdAt: -1 });
CallSchema.index({ status: 1, createdAt: -1 });

// `roomId` already gets its own unique index from the field definition.

module.exports = mongoose.model('Call', CallSchema);
