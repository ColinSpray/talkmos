const express = require('express');
const router = express.Router();
const {
  initiateCall,
  joinCall,
  declineCall,
  leaveCall,
  endCall,
  addParticipants,
  getCallById,
  getChatCallHistory,
  getMyCallHistory,
} = require('./callController');
const { protect } = require('../../middleware/authMiddleware');
const { validate, registerIdParams } = require('../../middleware/validate');
const schema = require('./callValidation');

registerIdParams(router);

// ─── HISTORY (static routes first to avoid :id conflict) ─────────────────────
router.get('/me/history', protect, validate(schema.myHistory), getMyCallHistory);
router.get('/chat/:chatId', protect, validate(schema.chatHistory), getChatCallHistory);

// ─── CALL LIFECYCLE ───────────────────────────────────────────────────────────
router.post('/', protect, validate(schema.initiateCall), initiateCall);
router.get('/:id', protect, getCallById);
router.post('/:id/join', protect, joinCall);
router.post('/:id/decline', protect, declineCall);
router.post('/:id/leave', protect, leaveCall);
router.post('/:id/end', protect, validate(schema.endCall), endCall);
router.post('/:id/participants', protect, validate(schema.addParticipants), addParticipants);

module.exports = router;
