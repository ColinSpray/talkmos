const mongoose = require('mongoose');

const MessageReactionSchema = new mongoose.Schema(
  {
    messageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    emoji: {
      type: String,
      required: true,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

MessageReactionSchema.index({ messageId: 1, userId: 1, emoji: 1 }, { unique: true });
module.exports = mongoose.model('MessageReaction', MessageReactionSchema);
