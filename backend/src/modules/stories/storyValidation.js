const { str, url } = require('../../utils/validators');

const MEDIA_TYPES = ['image', 'video'];
const VISIBILITY = ['public', 'friends'];

const createStory = {
  body: {
    mediaUrl: url({ required: true }),
    mediaType: str({ required: true, values: MEDIA_TYPES }),
    caption: str({ max: 500 }),
    category: str({ max: 50 }),
    visibility: str({ values: VISIBILITY }),
  },
};

const getDiscoverFeed = {
  query: { category: str({ max: 50 }) },
};

module.exports = { createStory, getDiscoverFeed };
