const express = require('express');
const router = express.Router();
const {
  getStoriesFeed,
  getDiscoverFeed,
  getStory,
  createStory,
  viewStory,
  getStoryViews,
  deleteStory,
} = require('./storyController');
const { protect } = require('../../middleware/authMiddleware');
const { rateLimiter } = require('../../middleware/rateLimit');
const { validate, registerIdParams } = require('../../middleware/validate');
const schema = require('./storyValidation');

// Story creation and view-marking were unbounded. Views are generous because
// scrolling a feed legitimately fires one per story.
const createLimiter = rateLimiter({ points: 30, duration: 300, keyPrefix: 'rl:story-create' });
const viewLimiter = rateLimiter({ points: 300, duration: 60, keyPrefix: 'rl:story-view' });

registerIdParams(router);

router.get('/feed', protect, getStoriesFeed);
router.get('/discover', protect, validate(schema.getDiscoverFeed), getDiscoverFeed);
router.post('/', protect, createLimiter, validate(schema.createStory), createStory);
// Deep-link landing for a single story. Must come after /feed and /discover
// (already fixed literal segments, no ambiguity) but is otherwise order-safe.
router.get('/:id', protect, getStory);
router.post('/:id/view', protect, viewLimiter, viewStory);
router.get('/:id/views', protect, getStoryViews);
router.delete('/:id', protect, deleteStory);

module.exports = router;
