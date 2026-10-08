const Story = require('../../../models/Story');
const StoryView = require('../../../models/StoryView');

const getStoryViews = async ({ storyId, userId }) => {
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

  return StoryView.find({ storyId })
    .populate('viewerId', 'name avatarUrl status')
    .lean();
};

module.exports = getStoryViews;
