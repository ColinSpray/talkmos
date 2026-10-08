const Story = require('../../../models/Story');
const StoryView = require('../../../models/StoryView');
const storyCache = require('../../../services/storyCache');
const logger = require('../../../utils/logger');

const pruneExpiredStories = async () => {
  try {
    // userId comes along now so the authors' cached lists can be dropped too.
    const expired = await Story.find({ expiresAt: { $lte: new Date() } })
      .select('_id userId')
      .lean();
    if (expired.length === 0) return;

    const ids = expired.map((s) => s._id);
    const authorIds = [...new Set(expired.map((s) => String(s.userId)))];

    await Promise.all([
      Story.deleteMany({ _id: { $in: ids } }),
      StoryView.deleteMany({ storyId: { $in: ids } }),
      storyCache.dropStories(ids, authorIds),
    ]);
    logger.info(`[PRUNER] Purged ${expired.length} expired stories`);
  } catch (error) {
    logger.error(`[PRUNER] Error pruning expired stories: ${error.message}`);
  }
};

module.exports = pruneExpiredStories;
