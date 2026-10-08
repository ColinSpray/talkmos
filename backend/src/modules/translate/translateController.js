const logger = require('../../utils/logger');

const TRANSLATE_SERVICE_URL =
  process.env.TRANSLATE_SERVICE_URL || 'http://host.docker.internal:6010';

// 1. TRANSLATE TEXT
const translateText = async (req, res) => {
  try {
    const response = await fetch(`${TRANSLATE_SERVICE_URL}/translate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body),
    });
    const data = await response.json();

    if (!response.ok) {
      const status = response.status === 400 ? 400 : 502;
      return res.status(status).json({ success: false, message: data.error || 'Translation service error' });
    }

    return res.json({ success: true, data: { translatedText: data.translatedText } });
  } catch (error) {
    logger.error(`[Translate] ${error.message}`);
    return res.status(503).json({ success: false, message: 'Translation service is unavailable' });
  }
};

// 2. LIST SUPPORTED LANGUAGES (proxied straight through)
const getSupportedLanguages = async (req, res) => {
  try {
    const response = await fetch(`${TRANSLATE_SERVICE_URL}/languages`);
    const data = await response.json();

    if (!response.ok) {
      return res.status(502).json({ success: false, message: 'Translation service error' });
    }

    return res.json({ success: true, data });
  } catch (error) {
    logger.error(`[Translate] ${error.message}`);
    return res.status(503).json({ success: false, message: 'Translation service is unavailable' });
  }
};

module.exports = {
  translateText,
  getSupportedLanguages,
};
