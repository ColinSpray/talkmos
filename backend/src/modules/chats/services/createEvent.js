const Event = require('../../../models/Event');
const Space = require('../../../models/Space');
const { assertMembership } = require('./helpers');
const Chat = require('../../../models/Chat');

const createEvent = async ({ userId, spaceId, title, description, startTime, endTime, location, instant }) => {
  const space = await Space.findById(spaceId);
  if (!space) {
    throw new Error('Space not found');
  }

  // Find general chat to check membership
  const chat = await Chat.findOne({ spaceId, chatType: 'community' });
  if (!chat) {
    throw new Error('General chat for space not found');
  }
  await assertMembership(chat._id, userId);

  const event = await Event.create({
    communityId: spaceId,
    title,
    description: description || '',
    startTime: startTime ? new Date(startTime) : new Date(),
    endTime: endTime ? new Date(endTime) : new Date(Date.now() + 3600000), // default 1 hour later
    location: location || 'Online',
    createdBy: userId,
  });

  return event;
};

module.exports = createEvent;
