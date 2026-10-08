const Story = require('../../../models/Story');
const StoryView = require('../../../models/StoryView');
const storyCache = require('../../../services/storyCache');

const viewStory = async ({ storyId, viewerId }) => {
  const story = await Story.findById(storyId).select('expiresAt').lean();
  if (!story || new Date(story.expiresAt) <= new Date()) {
    const err = new Error('Story not found or expired');
    err.statusCode = 404;
    throw err;
  }

  const [view] = await Promise.all([
    StoryView.findOneAndUpdate(
      { storyId, viewerId },
      { viewedAt: new Date() },
      { upsert: true, new: true }
    ),
    storyCache.addViewer(storyId, viewerId, story.expiresAt),
  ]);

  return view;
};

module.exports = viewStory;
