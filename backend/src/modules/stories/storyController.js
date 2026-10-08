const logger = require('../../utils/logger');
const storyService = require('./services');

const handleError = (res, error) => {
  logger.error(error);
  return res.status(error.statusCode || 500).json({ success: false, message: error.message });
};

const getStoriesFeed = async (req, res) => {
  try {
    const data = await storyService.getStoriesFeed(req.user.id);
    return res.json({ success: true, data });
  } catch (error) {
    return handleError(res, error);
  }
};

const getDiscoverFeed = async (req, res) => {
  try {
    const data = await storyService.getDiscoverFeed(req.user.id, req.query.category);
    return res.json({ success: true, data });
  } catch (error) {
    return handleError(res, error);
  }
};

const createStory = async (req, res) => {
  try {
    const { mediaUrl, mediaType, caption, category, visibility } = req.body;
    const data = await storyService.createStory({ userId: req.user.id, mediaUrl, mediaType, caption, category, visibility });
    return res.status(201).json({ success: true, data });
  } catch (error) {
    return handleError(res, error);
  }
};

const getStory = async (req, res) => {
  try {
    const data = await storyService.getStoryById({ storyId: req.params.id, viewerId: req.user.id });
    return res.json({ success: true, data });
  } catch (error) {
    return handleError(res, error);
  }
};

const viewStory = async (req, res) => {
  try {
    const data = await storyService.viewStory({ storyId: req.params.id, viewerId: req.user.id });
    return res.json({ success: true, data });
  } catch (error) {
    return handleError(res, error);
  }
};

const getStoryViews = async (req, res) => {
  try {
    const data = await storyService.getStoryViews({ storyId: req.params.id, userId: req.user.id });
    return res.json({ success: true, data });
  } catch (error) {
    return handleError(res, error);
  }
};

const deleteStory = async (req, res) => {
  try {
    await storyService.deleteStory({ storyId: req.params.id, userId: req.user.id });
    return res.json({ success: true, message: 'Story deleted successfully' });
  } catch (error) {
    return handleError(res, error);
  }
};

const { pruneExpiredStories } = storyService;

module.exports = {
  getStoriesFeed,
  getDiscoverFeed,
  getStory,
  createStory,
  viewStory,
  getStoryViews,
  deleteStory,
  pruneExpiredStories,
};
