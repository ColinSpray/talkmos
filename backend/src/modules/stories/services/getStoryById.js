const Story = require('../../../models/Story');
const { areContacts, isBlockedEitherWay } = require('../../users/services/privacy');

const getStoryById = async ({ storyId, viewerId }) => {
  const story = await Story.findById(storyId).populate('userId', 'name avatarUrl isPublic').lean();
  if (!story || story.expiresAt <= new Date()) {
    const err = new Error('Story not found or expired');
    err.statusCode = 404;
    throw err;
  }

  const ownerId = story.userId?._id;
  const isOwner = String(ownerId) === String(viewerId);

  if (!isOwner) {
    if (await isBlockedEitherWay(viewerId, ownerId)) {
      const err = new Error('Story not found or expired');
      err.statusCode = 404;
      throw err;
    }
    if (story.visibility === 'friends' && !(await areContacts(viewerId, ownerId))) {
      const err = new Error('This story is only visible to friends');
      err.statusCode = 403;
      throw err;
    }
  }

  return story;
};

module.exports = getStoryById;
