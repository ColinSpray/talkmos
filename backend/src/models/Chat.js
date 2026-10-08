const mongoose = require("mongoose");

const ChatSchema = new mongoose.Schema(
  {
    chatType: {
      type: String,
      enum: ["direct", "group", "community"],
      required: true,
    },
    spaceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Space",
      default: null,
    },
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    receiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    activeCall: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Call",
      default: null,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
    lastMessageAt: {
      type: Date,
      default: Date.now,
    },
    permissions: {
      sendMessages: {
        type: String,
        enum: ["everyone", "admins"],
        default: "everyone",
      },
      editInfo: {
        type: String,
        enum: ["everyone", "admins"],
        default: "admins",
      },
      addMembers: {
        type: String,
        enum: ["everyone", "admins"],
        default: "admins",
      },
    },
  },
  {
    timestamps: true,
  }
);

ChatSchema.index({
  sender: 1,
  receiver: 1
},
  {
    unique: true,
    partialFilterExpression: {
      chatType: "direct"
    }
  }
);

// Conversation list: match one arm of the $or, then sort newest-first.
ChatSchema.index({ sender: 1, deletedAt: 1, lastMessageAt: -1 });
ChatSchema.index({ receiver: 1, deletedAt: 1, lastMessageAt: -1 });

ChatSchema.index({ chatType: 1, deletedAt: 1 });

ChatSchema.index(
  { spaceId: 1, chatType: 1 },
  { partialFilterExpression: { spaceId: { $type: "objectId" } } }
);

ChatSchema.index(
  { activeCall: 1 },
  { partialFilterExpression: { activeCall: { $type: "objectId" } } }
);

module.exports = mongoose.model("Chat", ChatSchema);
