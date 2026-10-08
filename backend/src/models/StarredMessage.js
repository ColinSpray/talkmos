const mongoose = require('mongoose');

const StarredMessageSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    messageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

StarredMessageSchema.index({ userId: 1, messageId: 1 }, { unique: true });

module.exports = mongoose.model('StarredMessage', StarredMessageSchema);
