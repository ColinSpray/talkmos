const Event = require('../../../models/Event');

const getEvents = async ({ spaceId }) => {
  return Event.find({ communityId: spaceId })
    .populate('createdBy', 'name avatarUrl')
    .sort({ startTime: 1 })
    .lean();
};

module.exports = getEvents;
