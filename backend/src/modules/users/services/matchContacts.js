const User = require('../../../models/User');
const FriendRequest = require('../../../models/FriendRequest');

const SUFFIX_LENGTH = User.PHONE_SUFFIX_LENGTH;
const MAX_CONTACTS = 2000;

/// Same definition as the model's, reused so the two cannot drift.
const suffixOf = (value) => User.phoneSuffixOf(value);

const matchContacts = async ({ userId, phones = [] }) => {
  const suffixes = new Map(); // suffix -> original input
  for (const raw of phones.slice(0, MAX_CONTACTS)) {
    const suffix = suffixOf(raw);
    if (suffix && !suffixes.has(suffix)) {
      suffixes.set(suffix, String(raw));
    }
  }
  if (suffixes.size === 0) return [];

  const users = await User.find({
    _id: { $ne: userId },
    phoneSuffix: { $in: [...suffixes.keys()] },
  })
    .select('_id name username avatarUrl phone phoneSuffix isPublic isVerified status')
    .lean();

  if (users.length === 0) return [];

  // One query for every relationship this user has with the matches.
  const ids = users.map((u) => u._id);
  const relations = await FriendRequest.find({
    $or: [
      { sender: userId, receiver: { $in: ids } },
      { sender: { $in: ids }, receiver: userId },
    ],
  })
    .select('sender receiver status')
    .lean();

  const relationFor = (otherId) =>
    relations.find(
      (r) =>
        String(r.sender) === String(otherId) ||
        String(r.receiver) === String(otherId)
    );

  return users.map((u) => {
    const relation = relationFor(u._id);
    let friendship = 'none';
    if (relation) {
      if (relation.status === 'accepted') friendship = 'friends';
      else if (relation.status === 'pending') {
        friendship =
          String(relation.sender) === String(userId)
            ? 'request_sent'
            : 'request_received';
      }
    }

    return {
      _id: u._id,
      name: u.name,
      username: u.username || '',
      avatarUrl: u.avatarUrl || '',
      phone: u.phone,
      isPublic: !!u.isPublic,
      isVerified: !!u.isVerified,
      status: u.status,
      friendship,
      matchedContact: suffixes.get(u.phoneSuffix || suffixOf(u.phone)) || u.phone,
    };
  });
};

module.exports = matchContacts;
