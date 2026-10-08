const mongoose = require("mongoose");

const userChatPreferenceSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Chat",
      required: true,
    },
    chatMemberId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ChatMember",
    },
    isArchived: {
      type: Boolean,
      default: false,
    },
    isMuted: {
      type: Boolean,
      default: false,
    },
    mutedUntil: {
      type: Date,
      default: null,
    },
    isPinned: {
      type: Boolean,
      default: false,
    },
    hiddenAt: {
      type: Date,
      default: null,
    },
    lastDeliveredMessage: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Message",
      default: null,
    },
    lastReadMessage: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Message",
      default: null,
    },
    lastReadAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Per-chat prefs lookup — findOne / findOneAndUpdate by this exact pair.
userChatPreferenceSchema.index({ userId: 1, chatId: 1 }, { unique: true });
userChatPreferenceSchema.index({ chatId: 1, userId: 1 });

module.exports = mongoose.model(
  "UserChatPreference",
  userChatPreferenceSchema
);
