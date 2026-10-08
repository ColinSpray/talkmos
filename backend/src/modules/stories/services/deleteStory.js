const Story = require('../../../models/Story');
const StoryView = require('../../../models/StoryView');
const storyCache = require('../../../services/storyCache');

const deleteStory = async ({ storyId, userId }) => {
  const story = await Story.findById(storyId);
  if (!story) {
    const err = new Error('Story not found');
    err.statusCode = 404;
    throw err;
  }
  if (String(story.userId) !== String(userId)) {
    const err = new Error('Forbidden: You do not own this story');
    err.statusCode = 403;
    throw err;
  }

  await Promise.all([
    Story.deleteOne({ _id: storyId }),
    StoryView.deleteMany({ storyId }),
    // Evict before the response returns, so a feed reloaded straight after a
    // delete cannot still be served the story — from its author's cached list
    // or, for a public one, from the discover lists it was in.
    storyCache.dropStories(
      [storyId],
      [userId],
      story.visibility === 'public' ? [story.category] : []
    ),
  ]);
};

module.exports = deleteStory;
