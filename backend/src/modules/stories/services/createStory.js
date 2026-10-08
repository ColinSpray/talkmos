const Story = require('../../../models/Story');
const storyCache = require('../../../services/storyCache');

const createStory = async ({ userId, mediaUrl, mediaType, caption, category, visibility }) => {
  const story = await Story.create({
    userId,
    mediaUrl,
    mediaType,
    caption: caption || '',
    category: category || 'Friends',
    visibility: visibility || 'friends',
  });

  await storyCache.invalidateUser(userId);

  return story;
};

module.exports = createStory;
