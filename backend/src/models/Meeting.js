const mongoose = require('mongoose');

const MeetingSchema = new mongoose.Schema(
  {
    meetingCode: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    hostId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: ['instant', 'scheduled'],
      required: true,
    },
    scheduledAt: {
      type: Date,
      default: null,
    },
    status: {
      type: String,
      enum: ['scheduled', 'ongoing', 'ended'],
      default: 'scheduled',
    },
    joinLink: {
      type: String,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// A host's own meetings, newest first.
MeetingSchema.index({ hostId: 1, createdAt: -1 });

module.exports = mongoose.model('Meeting', MeetingSchema);
