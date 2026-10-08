const Meeting = require('../../../models/Meeting');
const { generateMeetingCode } = require('./helpers');

const createMeeting = async ({ userId, type, scheduledAt }) => {
  const meetingCode = generateMeetingCode();
  const joinLink = `https://talkmos.com/meet/${meetingCode}`;

  const meeting = await Meeting.create({
    meetingCode,
    hostId: userId,
    type: type || 'instant',
    scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
    status: type === 'scheduled' ? 'scheduled' : 'ongoing',
    joinLink,
  });

  return meeting;
};

module.exports = createMeeting;
