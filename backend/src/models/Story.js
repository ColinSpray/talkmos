const mongoose = require('mongoose');

const StorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    mediaUrl: {
      type: String,
      required: true,
    },
    mediaType: {
      type: String,
      enum: ['image', 'video'],
      required: true,
    },
    caption: {
      type: String,
      default: '',
    },
    visibility: {
      type: String,
      enum: ['public', 'friends'],
      default: 'friends',
    },
    category: {
      type: String,
      default: 'Friends', // default category
    },
    expiresAt: {
      type: Date,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// pruneExpiredStories: find({ expiresAt: { $lte: now } }).
StorySchema.index({ expiresAt: 1 });

// getStoriesFeed: the own-and-friends arm, find({ userId: { $in: [...] },
// expiresAt: { $gt: now } }). Also serves the admin list's userId filter.
StorySchema.index({ userId: 1, expiresAt: 1 });

StorySchema.index({ visibility: 1, category: 1, expiresAt: 1 });

// Pre-save hook to calculate expiry time (24 hours from creation)
StorySchema.pre('validate', function (next) {
  if (!this.expiresAt) {
    this.expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
  }
  next();
});

module.exports = mongoose.model('Story', StorySchema);
