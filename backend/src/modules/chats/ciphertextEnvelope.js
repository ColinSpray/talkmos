// Ciphertext written by a client carries the key it was written under, as a
// `k<id>.` prefix in front of the payload: `k2.<nonceB64>:<macB64>:<cipherB64>`.
// The original scheme predates the prefix and is key 0, so an unprefixed
// payload is not ambiguous — it is key 0 by definition.
const ENVELOPE = /^k(\d+)\./;

// The key id `content` was encrypted under. Reading it off the ciphertext
// keeps it honest: a client cannot claim one key and encrypt with another,
// the way a separate request field would allow.
const keyIdOf = (content) => {
  const match = ENVELOPE.exec(String(content || ''));
  return match ? Number(match[1]) : 0;
};

module.exports = { keyIdOf };
