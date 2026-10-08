const mongoose = require('mongoose');

const StoryViewSchema = new mongoose.Schema(
  {
    storyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Story',
      required: true,
    },
    viewerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    viewedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

StoryViewSchema.index({ storyId: 1, viewerId: 1 }, { unique: true });

module.exports = mongoose.model('StoryView', StoryViewSchema);
