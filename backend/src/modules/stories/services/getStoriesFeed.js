const Story = require('../../../models/Story');
const StoryView = require('../../../models/StoryView');
const FriendRequest = require('../../../models/FriendRequest');
const User = require('../../../models/User');
const storyCache = require('../../../services/storyCache');
const { loadPublicStories, primeViewersFor, AUTHOR_FIELDS } = require('./loadPublicStories');

const loadAuthorStories = async (authorIds, now) => {
  const { hits, misses } = await storyCache.getUserStories(authorIds);

  if (misses.length > 0) {
    const fresh = await Story.find({ userId: { $in: misses }, expiresAt: { $gt: now } })
      .populate('userId', AUTHOR_FIELDS)
      .sort({ createdAt: -1 })
      .lean();

    const byUser = new Map(misses.map((id) => [id, []]));
    for (const story of fresh) {
      const uid = String(story.userId?._id || story.userId);
      if (byUser.has(uid)) byUser.get(uid).push(story);
    }
    await Promise.all([storyCache.setUserStories(byUser), primeViewersFor(fresh)]);
    for (const [uid, list] of byUser) hits.set(uid, list);
  }

  return [...hits.values()].flat();
};

const getStoriesFeed = async (userId) => {
  const now = new Date();

  const [friendships, viewer] = await Promise.all([
    FriendRequest.find({
      status: 'accepted',
      $or: [{ sender: userId }, { receiver: userId }],
    })
      .select('sender receiver')
      .lean(),
    User.findById(userId).select('isBlocked').lean(),
  ]);

  const friendIds = friendships.map((f) =>
    String(f.sender) === String(userId) ? String(f.receiver) : String(f.sender)
  );
  const blocked = new Set((viewer?.isBlocked || []).map(String));
  const authorIds = [...new Set([String(userId), ...friendIds])];

  const [ownAndFriends, publicStories] = await Promise.all([
    loadAuthorStories(authorIds, now),
    loadPublicStories(null),
  ]);

  const seen = new Set();
  const stories = [];
  for (const story of [...ownAndFriends, ...publicStories]) {
    const id = String(story._id);
    if (seen.has(id)) continue;
    if (blocked.has(String(story.userId?._id || story.userId))) continue;
    // A cached list can outlive an individual story's expiry by a few seconds.
    if (new Date(story.expiresAt) <= now) continue;
    seen.add(id);
    stories.push(story);
  }

  stories.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  // Seen-state from Redis when it can answer, Mongo when it cannot.
  const storyIds = stories.map((s) => String(s._id));
  let viewedSet = await storyCache.filterViewed(storyIds, userId);
  if (viewedSet === null) {
    const viewed = await StoryView.find({ storyId: { $in: storyIds }, viewerId: userId })
      .select('storyId')
      .lean();
    viewedSet = new Set(viewed.map((v) => String(v.storyId)));
  }

  // Group by user
  const grouped = {};
  for (const story of stories) {
    const uId = String(story.userId?._id || story.userId);
    if (!grouped[uId]) grouped[uId] = { user: story.userId, stories: [] };
    grouped[uId].stories.push({ ...story, viewed: viewedSet.has(String(story._id)) });
  }

  return Object.values(grouped);
};

module.exports = getStoriesFeed;
