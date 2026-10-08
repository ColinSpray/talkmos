const mongoose = require('mongoose');
const User = require('../../../models/User');
const FriendRequest = require('../../../models/FriendRequest');

const isValidId = (id) => !!id && mongoose.isValidObjectId(id);

const areContacts = async (userIdA, userIdB) => {
  if (!isValidId(userIdA) || !isValidId(userIdB)) return false;
  if (String(userIdA) === String(userIdB)) return true;
  const friendship = await FriendRequest.findOne({
    status: 'accepted',
    $or: [
      { sender: userIdA, receiver: userIdB },
      { sender: userIdB, receiver: userIdA },
    ],
  }).lean();
  return !!friendship;
};

const isBlockedEitherWay = async (userIdA, userIdB) => {
  if (!isValidId(userIdA) || !isValidId(userIdB)) return false;
  if (String(userIdA) === String(userIdB)) return false;
  return !!(await User.exists({
    $or: [
      { _id: userIdA, isBlocked: userIdB },
      { _id: userIdB, isBlocked: userIdA },
    ],
  }));
};

const isVisible = async (viewerId, ownerId, visibility) => {
  if (String(viewerId) === String(ownerId)) return true;
  if (visibility === 'Nobody') return false;
  if (visibility === 'Contacts') return areContacts(viewerId, ownerId);
  return true; // 'Everyone' (and any unset/default value)
};

const canViewPresence = async (viewerId, ownerId) => {
  if (!isValidId(ownerId)) return false;
  if (String(viewerId) === String(ownerId)) return true;
  const owner = await User.findById(ownerId).select('lastSeenVisibility').lean();
  return isVisible(viewerId, ownerId, owner?.lastSeenVisibility);
};

const canViewProfilePhoto = async (viewerId, ownerId) => {
  if (!isValidId(ownerId)) return false;
  if (String(viewerId) === String(ownerId)) return true;
  const owner = await User.findById(ownerId).select('profilePhotoVisibility').lean();
  return isVisible(viewerId, ownerId, owner?.profilePhotoVisibility);
};

const canInitiateWith = async (viewerId, ownerId) => {
  if (!isValidId(ownerId)) return false;
  if (String(viewerId) === String(ownerId)) return true;
  if (await isBlockedEitherWay(viewerId, ownerId)) return false;
  const owner = await User.findById(ownerId).select('isPublic').lean();
  if (owner?.isPublic) return true;
  return areContacts(viewerId, ownerId);
};

module.exports = {
  areContacts,
  isBlockedEitherWay,
  canViewPresence,
  canViewProfilePhoto,
  canInitiateWith,
};
