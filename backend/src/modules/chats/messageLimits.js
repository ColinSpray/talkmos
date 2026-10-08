// A single text message carries at most 4096 characters of plaintext.
const MAX_TEXT_CHARS = 4096;

// The server never sees the plaintext, only `k<id>.<nonceB64>:<macB64>:<cipherB64>`,
// so the cap it can enforce is the largest envelope those 4096 characters can
// produce: 3 UTF-8 bytes per unit the client counts, base64'd, plus the frame.
const ENVELOPE_OVERHEAD = 48;
const MAX_CONTENT = ENVELOPE_OVERHEAD + Math.ceil((MAX_TEXT_CHARS * 3) / 3) * 4;

const assertContentLength = (content) => {
  if ((content || '').length <= MAX_CONTENT) return;
  const err = new Error(`A message can be at most ${MAX_TEXT_CHARS} characters`);
  err.statusCode = 400;
  throw err;
};

module.exports = {
  MAX_TEXT_CHARS,
  MAX_CONTENT,
  assertContentLength,
};
