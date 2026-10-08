const { loadPublicStories } = require('./loadPublicStories');

const getDiscoverFeed = async (userId, category) => {
  const stories = await loadPublicStories(category || null);
  const now = new Date();

  return stories.filter(
    (s) =>
      String(s.userId?._id || s.userId) !== String(userId) &&
      new Date(s.expiresAt) > now
  );
};

module.exports = getDiscoverFeed;
