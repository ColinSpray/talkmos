const logger = require('../../utils/logger');

// The salt the message key is derived from. It used to ship inside the app's
// bundled .env, which meant it was in every APK and identical for everyone —
// anyone could unzip an install and read it. Serving it to authenticated
// clients instead keeps it off the device image and makes it rotatable
// without a release.
const SALT_ENV = 'MESSAGE_KEY_SALT';

// Sent as a template rather than assumed by the client, so the derivation can
// change without shipping an app update. The client substitutes the two
// placeholders and hashes the result.
const KEY_TEMPLATE = '{userId}{salt}{chatId}';

// Bumped whenever the salt or the template changes. Clients stamp it into the
// ciphertext envelope (`k<id>.<payload>`, mirrored onto Message.keyId), so
// messages written under an older key stay readable instead of turning into
// garbage the moment a rotation happens.
//
// Never defaulted. A guessed id makes clients encrypt under a key nobody else
// derives, and nothing about that failure is visible until someone tries to
// read the message. server.js refuses to boot without it; this is the second
// line of defence for anything that loads the module directly.
const ID_ENV = 'MESSAGE_KEY_ID';

const keyId = () => {
  const value = Number(process.env[ID_ENV]);
  if (!Number.isInteger(value) || value < 0) {
    const err = new Error('Message encryption is not configured on this server');
    err.status = 503;
    throw err;
  }
  return value;
};

// Only a presence check. The length is not this route's call to make: the
// value has to stay byte-identical to the salt the existing messages were
// encrypted under, so rejecting a short one here would take the whole chat
// history offline rather than improve anything.
const salt = () => {
  const value = process.env[SALT_ENV];
  if (!value) {
    const err = new Error('Message encryption is not configured on this server');
    err.status = 503;
    throw err;
  }
  return value;
};

/**
 * Hands the caller what it needs to derive its own message key.
 *
 * Deliberately returns no per-user material and stores nothing: the formula
 * plus the caller's own id is the whole input, so there is no key table to
 * leak and nothing to keep in sync.
 */
const getMessageKey = async (req, res) => {
  try {
    return res.json({
      success: true,
      data: {
        keyId: keyId(),
        algorithm: 'aes-256-gcm',
        kdf: 'sha256',
        template: KEY_TEMPLATE,
        salt: salt(),
      },
    });
  } catch (error) {
    if (error.status) {
      // Logged without the reason the client sees, so a missing salt shows up
      // in the server log rather than only on someone's phone.
      logger.error(`[keys] message key unavailable: ${error.message}`);
      return res.status(error.status).json({ success: false, message: error.message });
    }
    logger.error(`[keys] ${error.message}`);
    return res.status(500).json({ success: false, message: 'Could not read the encryption key' });
  }
};

module.exports = { getMessageKey, KEY_TEMPLATE, SALT_ENV, ID_ENV };
