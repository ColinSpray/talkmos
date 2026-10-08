# Keys API

Base path: `/api/v1/keys`

> Shared conventions — auth header, error envelope, status codes: **[README.md](README.md)**
> **All endpoints in this module require 🔒 `Authorization: Bearer <jwt>`.**

Message bodies are encrypted on the device; the server stores only ciphertext and never holds a plaintext message. This module hands an authenticated client the *formula* it needs to derive the key itself — no per-user key material is stored or transmitted, so there is no key table to leak.

The salt used to ship inside the app bundle, which meant it was identical for everyone and readable by anyone who unzipped an APK. Serving it here keeps it off the device image and makes it rotatable without a release.

---

## Routes at a glance

| Method | Path | Purpose |
|---|---|---|
| `GET` | [`/message`](#get-keysmessage) | Fetch the message-key formula |

---

## `GET /keys/message`

Rate limited to **20 requests per 5 minutes per account**. Fetch once per launch and cache it; anything more often is a bug.

### Response `200`

```json
{
  "success": true,
  "data": {
    "keyId": 0,
    "algorithm": "aes-256-gcm",
    "kdf": "sha256",
    "template": "{userId}{salt}{chatId}",
    "salt": "<server-held salt>"
  }
}
```

| Field | Meaning |
|---|---|
| `keyId` | Which key this formula is. Stamped into every ciphertext written under it — see [Envelope](#envelope) |
| `algorithm` | Content cipher. `aes-256-gcm` |
| `kdf` | How the derived string becomes a 32-byte key. `sha256` |
| `template` | Substitute `{userId}`, `{salt}`, `{chatId}`, then hash |
| `salt` | The secret half of the derivation |

### Deriving the key

```
key = SHA256( template with {userId} → sender's user id
                           {salt}   → salt from this response
                           {chatId} → conversation id )
```

`{userId}` is the id of the user who **sent** the message, not the reader — both sides derive the same key because the recipient takes it from `message.senderId`. `{chatId}` is the conversation the message belongs to.

Encrypt with AES-256-GCM, then format the result as below.

### Envelope

```
k<keyId>.<nonceB64>:<macB64>:<cipherB64>
```

The `k<id>.` prefix records which key wrote the message, so a rotation does not strand everything written before it. **`keyId: 0` is the original scheme and is written without a prefix** — an unprefixed payload is key 0 by definition, not an unknown one.

The server reads the prefix off `content` on write and mirrors it onto `Message.keyId`, so a future rotation can find what still needs re-encrypting with a single query. Nothing else on the server interprets the ciphertext.

> **Do not write a prefix the readers do not implement.** A client that starts emitting `k1.` ciphertext into a conversation whose other participants only understand key 0 makes those messages permanently unreadable to them, silently. Roll a new `keyId` out to every client *before* the server starts advertising it.

### Errors

| Code | Message | Meaning | Client action |
|---|---|---|---|
| `401` | *(auth envelope)* | Missing/expired token | Re-login |
| `429` | *(rate-limit envelope)* | More than 20 fetches in 5 minutes | Cache the response |
| `503` | `Message encryption is not configured on this server` | `MESSAGE_KEY_SALT` unset, or `MESSAGE_KEY_ID` unset/not a non-negative integer | Not recoverable client-side — keep using the cached formula |

---

## Server configuration

| Env var | Required | Notes |
|---|---|---|
| `MESSAGE_KEY_SALT` | at request time | Must stay **byte-identical** to the salt existing messages were encrypted under. Changing it without a `keyId` bump takes chat history offline |
| `MESSAGE_KEY_ID` | **at boot** | Non-negative integer. The process refuses to start without it — a guessed id makes clients encrypt under a key nobody else derives, and nothing about that failure is visible until someone tries to read the message |

---

## Integration notes

* **Cache it.** Keep the formula in secure storage. A client must be able to read its own history on a cold start with no network, and background isolates (push notifications) decrypt without ever reaching a screen that could report a failed fetch.
* **Keep key 0 support.** Even after a rotation, every client still needs the old key to read old messages. `Message.keyId` tells you which one a given message needs.
* **Never log the salt.**
