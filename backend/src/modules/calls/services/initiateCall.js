const crypto = require('crypto');
const Call = require('../../../models/Call');
const CallParticipant = require('../../../models/CallParticipant');
const Chat = require('../../../models/Chat');
const ChatMember = require('../../../models/ChatMember');
const { assertChatMembership } = require('./helpers');
const { canInitiateWith } = require('../../users/services/privacy');

const ACTIVE_STATUSES = ['ringing', 'ongoing'];

const initiateCall = async ({ chatId, callerId, callType }) => {
  if (!['audio', 'video'].includes(callType)) {
    throw new Error('callType must be "audio" or "video"');
  }

  const chat = await Chat.findById(chatId);
  if (!chat || chat.deletedAt) throw new Error('Chat not found');

  await assertChatMembership(chatId, callerId);

  if (chat.chatType === 'direct') {
    const calleeId = String(chat.sender) === String(callerId)
      ? chat.receiver
      : chat.sender;
    if (!(await canInitiateWith(callerId, calleeId))) {
      const err = new Error('You can only call friends or public accounts');
      err.statusCode = 403;
      throw err;
    }
  }

  const call = await Call.create({
    chatId,
    initiatedBy: callerId,
    callType,
    isGroupCall: chat.chatType !== 'direct',
    roomId: crypto.randomUUID(),
    status: 'ringing',
  });

  let members = [];
  if (chat.chatType === 'direct') {
    members = [
      { userId: chat.sender },
      { userId: chat.receiver },
    ];
  } else {
    members = await ChatMember.find({ chatId, isRemoved: false })
      .select('userId')
      .lean();
  }
  await Promise.all(
    members.map((m) => {
      const isCaller = String(m.userId) === String(callerId);
      return CallParticipant.create({
        callId: call._id,
        userId: m.userId,
        status: isCaller ? 'joined' : 'ringing',
        joinedAt: isCaller ? new Date() : null,
      });
    })
  );

  chat.activeCall = call._id;
  await chat.save();

  const participants = await CallParticipant.find({ callId: call._id })
    .populate('userId', 'name avatarUrl')
    .lean();

  return { call, participants };
};

module.exports = initiateCall;
