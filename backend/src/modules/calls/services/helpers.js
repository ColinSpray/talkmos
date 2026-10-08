const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const Call = require('../../../models/Call');
const CallParticipant = require('../../../models/CallParticipant');

const TERMINAL_STATUSES = ['ended', 'missed', 'declined', 'failed'];

const attachParticipants = async (calls) => {
  if (calls.length === 0) return calls;

  const participants = await CallParticipant.find({
    callId: { $in: calls.map((c) => c._id) },
  })
    .populate('userId', 'name avatarUrl')
    .lean();

  const byCallId = new Map();
  for (const p of participants) {
    const key = String(p.callId);
    if (!byCallId.has(key)) byCallId.set(key, []);
    byCallId.get(key).push(p);
  }

  return calls.map((call) => ({
    ...call,
    participants: byCallId.get(String(call._id)) || [],
  }));
};

const assertChatMembership = async (chatId, userId) => {
  const membership = await ChatMember.findOne({ chatId, userId, isRemoved: false });
  if (membership) return membership;

  const chat = await Chat.findOne({ _id: chatId, deletedAt: null });
  if (chat?.chatType === 'direct') {
    if (chat.sender.equals(userId) || chat.receiver.equals(userId)) {
      return { _id: null, chatId: chat._id, userId, role: 'member', isRemoved: false, canSendMessages: true };
    }
  }

  const err = new Error('Not a member of this chat');
  err.statusCode = 403;
  throw err;
};

const getCallOr404 = async (callId) => {
  const call = await Call.findById(callId);
  if (!call) {
    const err = new Error('Call not found');
    err.statusCode = 404;
    throw err;
  }
  return call;
};

module.exports = { assertChatMembership, getCallOr404, attachParticipants, TERMINAL_STATUSES };
