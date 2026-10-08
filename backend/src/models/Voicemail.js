const mongoose = require('mongoose');

const VoicemailSchema = new mongoose.Schema(
  {
    callId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Call',
      required: true,
      index: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    recipientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    audioUrl: {
      type: String,
      required: true,
    },
    durationSeconds: {
      type: Number,
      required: true,
      min: 0,
    },
    isHeard: {
      type: Boolean,
      default: false,
    },
    heardAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

VoicemailSchema.index({ recipientId: 1, createdAt: -1 });
VoicemailSchema.index({ recipientId: 1, isHeard: 1 });
// "Voicemails I left", newest first — replaces the bare { senderId: 1 }.
VoicemailSchema.index({ senderId: 1, createdAt: -1 });

module.exports = mongoose.model('Voicemail', VoicemailSchema);
