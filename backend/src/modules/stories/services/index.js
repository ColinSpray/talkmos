const getStoriesFeed = require('./getStoriesFeed');
const getDiscoverFeed = require('./getDiscoverFeed');
const getStoryById = require('./getStoryById');
const createStory = require('./createStory');
const viewStory = require('./viewStory');
const getStoryViews = require('./getStoryViews');
const deleteStory = require('./deleteStory');
const pruneExpiredStories = require('./pruneExpiredStories');

module.exports = {
  getStoriesFeed,
  getDiscoverFeed,
  getStoryById,
  createStory,
  viewStory,
  getStoryViews,
  deleteStory,
  pruneExpiredStories,
};
