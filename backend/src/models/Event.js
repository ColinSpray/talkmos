const mongoose = require('mongoose');

const EventSchema = new mongoose.Schema(
  {
    communityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Community',
      default: null,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    startTime: {
      type: Date,
      required: true,
    },
    endTime: {
      type: Date,
      required: true,
    },
    location: {
      type: String,
      default: 'Online',
    },
    meetingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Meeting',
      default: null,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// getEvents: find({ communityId }).sort({ startTime: 1 }) — one index serves
// both the filter and the sort, which the bare { communityId: 1 } could not.
EventSchema.index({ communityId: 1, startTime: 1 });

module.exports = mongoose.model('Event', EventSchema);
