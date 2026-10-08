const mongoose = require("mongoose");

const MessageSchema = new mongoose.Schema(
  {
    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Chat",
      required: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    messageType: {
      type: String,
      enum: [
        "text",
        "image",
        "video",
        "audio",
        "voice",
        "file",
        "gif",
        "sticker",
        "location",
        "contact",
        "system",
      ],
      default: "text",
    },
    content: {
      type: String,
      trim: true,
      default: "",
    },
    keyId: {
      type: Number,
      default: 0,
    },
    media: {
      url: {
        type: String,
        default: "",
      },
      thumbnail: {
        type: String,
        default: "",
      },
      fileName: {
        type: String,
        default: "",
      },
      mimeType: {
        type: String,
        default: "",
      },
      size: {
        type: Number,
        default: 0,
      },
      duration: {
        type: Number,
        default: 0,
      },
    },
    mentions: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    replyTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Message",
      default: null,
    },
    forwarded: {
      type: Boolean,
      default: false,
    },
    edited: {
      type: Boolean,
      default: false,
    },
    editedAt: {
      type: Date,
      default: null,
    },
    status: {
      type: String,
      enum: [
        "sending",
        "sent",
        "delivered",
        "read",
        "failed",
      ],
      default: "sent",
    },
    isPinned: {
      type: Boolean,
      default: false,
    },
    pinnedAt: {
      type: Date,
      default: null,
    },
    deletedForEveryone: {
      type: Boolean,
      default: false,
    },
    deletedForMe: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// This is the highest-write collection in the app, so every index here is paid
// for on each insert. Only add one when a real endpoint needs it.

MessageSchema.index({ chatId: 1, createdAt: -1 });

MessageSchema.index({ chatId: 1, messageType: 1, createdAt: -1 });

MessageSchema.index(
  { chatId: 1, pinnedAt: -1 },
  { partialFilterExpression: { isPinned: true } }
);

module.exports = mongoose.model("Message", MessageSchema);
