const { str } = require('../../utils/validators');

const MAX_BODY_BYTES = 8192;

// The body is forwarded verbatim, so the upstream service owns the field
// names. Only the size and the fields this backend can recognise are checked
// here; anything else is passed through untouched.
const translateText = {
  body: {
    text: str({ max: 5000 }),
    q: str({ max: 5000 }),
  },
  allowUnknown: true,
  maxBytes: MAX_BODY_BYTES,
  check: (req) =>
    Object.keys(req.body).length > 0 ? null : 'Request body must not be empty',
};

module.exports = { translateText };
