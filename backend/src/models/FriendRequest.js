const mongoose = require('mongoose');

const FriendRequestSchema = new mongoose.Schema(
  {
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    receiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected'],
      default: 'pending'
    },
    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Chat',
      default: null
    },
    source: {
      type: String,
      enum: ['search', 'contacts', 'nearby', 'link'],
      default: 'search'
    },
    // The one opening line a nearby request may carry. Requests from every
    // other source have no message and leave this null.
    message: {
      type: String,
      default: null,
      maxlength: 200,
      trim: true
    },
    pairKey: {
      type: String,
      default: null,
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  });

const pairKeyOf = (a, b) => (a && b ? [String(a), String(b)].sort().join(':') : null);

FriendRequestSchema.pre('save', function (next) {
  if (this.isModified('sender') || this.isModified('receiver') || !this.pairKey) {
    this.pairKey = pairKeyOf(this.sender, this.receiver);
  }
  next();
});

FriendRequestSchema.pre(['findOneAndUpdate', 'updateOne'], function (next) {
  const update = this.getUpdate();
  if (!update) return next();
  const sender = update.sender ?? update.$set?.sender;
  const receiver = update.receiver ?? update.$set?.receiver;
  if (sender === undefined || receiver === undefined) return next();
  const key = pairKeyOf(sender, receiver);
  if (update.$set) update.$set.pairKey = key;
  else this.setUpdate({ ...update, pairKey: key });
  next();
});

FriendRequestSchema.statics.pairKeyOf = pairKeyOf;

// Direction-specific dedupe.
FriendRequestSchema.index({ sender: 1, receiver: 1 }, { unique: true });
FriendRequestSchema.index(
  { pairKey: 1 },
  { unique: true, partialFilterExpression: { pairKey: { $type: 'string' } } }
);
// Incoming requests, and the receiver arm of the both-directions $or that
// areContacts / matchContacts / getStoriesFeed all run.
FriendRequestSchema.index({ receiver: 1, status: 1 });
// Sent requests, and the sender arm of that same $or.
FriendRequestSchema.index({ sender: 1, status: 1 });

module.exports = mongoose.model('FriendRequest', FriendRequestSchema);
