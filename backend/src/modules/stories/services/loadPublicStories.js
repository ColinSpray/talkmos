const Story = require('../../../models/Story');
const StoryView = require('../../../models/StoryView');
const storyCache = require('../../../services/storyCache');

const AUTHOR_FIELDS = 'name avatarUrl isPublic';

// Bounds the query. Both feeds were previously unlimited, so the result grew
// with every public story posted inside the 24h window.
const PUBLIC_LIMIT = 200;

const loadPublicStories = async (category = null) => {
  const cached = await storyCache.getPublicStories(category);
  if (cached) return cached;

  const query = { visibility: 'public', expiresAt: { $gt: new Date() } };
  if (category) query.category = category;

  const stories = await Story.find(query)
    .populate('userId', AUTHOR_FIELDS)
    .sort({ createdAt: -1 })
    .limit(PUBLIC_LIMIT)
    .lean();

  await Promise.all([
    storyCache.setPublicStories(category, stories),
    primeViewersFor(stories),
  ]);
  return stories;
};

const primeViewersFor = async (stories) => {
  if (stories.length === 0) return;
  const views = await StoryView.find({ storyId: { $in: stories.map((s) => s._id) } })
    .select('storyId viewerId')
    .lean();
  if (views.length === 0) return;

  const byStory = new Map();
  for (const v of views) {
    const sid = String(v.storyId);
    if (!byStory.has(sid)) byStory.set(sid, []);
    byStory.get(sid).push(String(v.viewerId));
  }
  const expiryOf = new Map(stories.map((s) => [String(s._id), s.expiresAt]));
  await Promise.all(
    [...byStory].map(([sid, viewers]) =>
      storyCache.primeViewers(sid, viewers, expiryOf.get(sid))
    )
  );
};

module.exports = { loadPublicStories, primeViewersFor, AUTHOR_FIELDS, PUBLIC_LIMIT };
