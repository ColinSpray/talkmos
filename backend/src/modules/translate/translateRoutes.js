const express = require('express');
const router = express.Router();
const { translateText, getSupportedLanguages } = require('./translateController');
const { protect } = require('../../middleware/authMiddleware');
const { validate } = require('../../middleware/validate');
const schema = require('./translateValidation');

router.post('/', protect, validate(schema.translateText), translateText);
router.get('/languages', protect, getSupportedLanguages);

module.exports = router;
