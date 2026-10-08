const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const UserSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      trim: true,
      lowercase: true,
    },
    username: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
    email: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
      lowercase: true,
    },
    phone: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
    phoneSuffix: {
      type: String,
      default: null,
    },
    password: {
      type: String,
      required: [
        function () {
          return this.authProvider === 'local';
        },
        'Please add a password',
      ],
      minlength: [6, 'Password must be at least 6 characters'],
    },
    avatarUrl: {
      type: String,
      default: '',
    },
    bio: {
      type: String,
      default: '',
      trim: true,
    },
    location: {
      type: String,
      default: '',
      trim: true,
    },
    language: {
      type: String,
      default: 'en',
      trim: true,
    },
    status: {
      type: String,
      enum: ['online', 'offline', 'away', 'busy'],
      default: 'offline',
    },
    lastSeenAt: {
      type: Date,
      default: Date.now,
    },
    // Notification preferences
    notificationsEnabled: {
      type: Boolean,
      default: true,
    },
    notificationPreviewEnabled: {
      type: Boolean,
      default: true,
    },
    // Privacy preferences
    readReceiptsEnabled: {
      type: Boolean,
      default: true,
    },
    // Matches the exact casing used by the dropdown options in the Flutter
    // privacy settings screen ('Everyone' / 'Contacts' / 'Nobody').
    lastSeenVisibility: {
      type: String,
      enum: ['Everyone', 'Contacts', 'Nobody'],
      default: 'Everyone',
    },
    profilePhotoVisibility: {
      type: String,
      enum: ['Everyone', 'Contacts', 'Nobody'],
      default: 'Everyone',
    },
    nearbyEnabled: {
      type: Boolean,
      default: false,
    },
    nearbyLastOn: {
      type: Date,
      default: null,
    },
    lastKnownLocation: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
      at: { type: Date, default: null },
    },
    isBlocked: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    isVerified: {
      type: Boolean,
      default: false,
    },
    isPremium: {
      type: Boolean,
      default: false,
    },
    premiumExpiry: {
      type: Date,
      default: null,
    },
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },
    isPublic: {
      type: Boolean,
      default: true,
    },
    authProvider: {
      type: String,
      enum: ['local', 'google', 'apple', 'facebook', 'phone'],
      default: 'local',
    },
  },
  {
    timestamps: true,
  }
);

const SUFFIX_LENGTH = 10;

const phoneSuffixOf = (value) => {
  const digits = String(value || '').replace(/[^0-9]/g, '');
  if (digits.length < SUFFIX_LENGTH) return null;
  return digits.slice(-SUFFIX_LENGTH);
};

// Derive on save/create.
UserSchema.pre('save', function (next) {
  if (this.isModified('phone')) {
    this.phoneSuffix = phoneSuffixOf(this.phone);
  }
  next();
});

UserSchema.pre(['findOneAndUpdate', 'updateOne', 'updateMany'], function (next) {
  const update = this.getUpdate();
  if (!update) return next();

  const phone = update.phone !== undefined ? update.phone : update.$set?.phone;
  if (phone === undefined) return next();

  const suffix = phoneSuffixOf(phone);
  if (update.$set) update.$set.phoneSuffix = suffix;
  else this.setUpdate({ ...update, phoneSuffix: suffix });
  next();
});

UserSchema.statics.phoneSuffixOf = phoneSuffixOf;
UserSchema.statics.PHONE_SUFFIX_LENGTH = SUFFIX_LENGTH;

// Indexed lookup for contact sync.
UserSchema.index({ phoneSuffix: 1 }, { sparse: true });

// Hash password before saving
UserSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }
  if (!this.password) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Compare entered password with hashed password
UserSchema.methods.matchPassword = async function (enteredPassword) {
  if (!this.password) return false;
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', UserSchema);
