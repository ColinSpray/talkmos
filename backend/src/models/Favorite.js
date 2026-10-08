const mongoose = require('mongoose');

const FavoriteSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    favoriteUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    favoriteGroupId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Chat',
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

FavoriteSchema.index(
  { userId: 1, favoriteUserId: 1 },
  { unique: true, partialFilterExpression: { favoriteUserId: { $type: 'objectId' } } }
);
FavoriteSchema.index(
  { userId: 1, favoriteGroupId: 1 },
  { unique: true, partialFilterExpression: { favoriteGroupId: { $type: 'objectId' } } }
);

module.exports = mongoose.model('Favorite', FavoriteSchema);
