const mongoose = require("mongoose");

const ChatMemberSchema = new mongoose.Schema(
  {
    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Chat",
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    role: {
      type: String,
      enum: ["owner", "admin", "moderator", "member"],
      default: "member",
    },
    canSendMessages: {
      type: Boolean,
      default: true,
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
    leftAt: {
      type: Date,
      default: null,
    },
    isRemoved: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

ChatMemberSchema.index({ chatId: 1, userId: 1 }, { unique: true });
// "Active members of this chat" — the fan-out list behind every group message,
// group call and pin broadcast.
ChatMemberSchema.index({ chatId: 1, isRemoved: 1 });
// "My active chats" — drives the group half of the conversation list.
ChatMemberSchema.index({ userId: 1, isRemoved: 1 });

module.exports = mongoose.model("ChatMember", ChatMemberSchema);
