const { str, num, arr, objectId } = require('../../utils/validators');

const CALL_TYPES = ['audio', 'video'];
const END_STATUSES = ['ended', 'failed'];
const MAX_ADDED_PARTICIPANTS = 50;

const initiateCall = {
  body: {
    chatId: objectId({ required: true }),
    callType: str({ required: true, values: CALL_TYPES }),
    calleeName: str({ max: 100 }),
  },
};

const endCall = {
  body: { status: str({ values: END_STATUSES, default: 'ended' }) },
};

const addParticipants = {
  body: {
    userIds: arr({ required: true, of: objectId(), min: 1, max: MAX_ADDED_PARTICIPANTS }),
  },
};

const history = (defaultLimit) => ({
  query: { limit: num({ integer: true, min: 1, max: 100, clamp: true, default: defaultLimit }) },
});

module.exports = {
  initiateCall,
  endCall,
  addParticipants,
  chatHistory: history(30),
  myHistory: history(50),
};
