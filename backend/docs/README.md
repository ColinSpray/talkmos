# Talkmos Backend — API Documentation

Backend `v1.1.0` · Reference for frontend / client integration.

---

## Modules

| Doc | Base path | What's in it |
|---|---|---|
| [auth.md](auth.md) | `/api/v1/auth` | Register, login, Google, phone OTP, password reset, profile, device sessions, FCM token |
| [users.md](users.md) | `/api/v1/users` | Search, contact sync, friend requests, blocking, Nearby discovery |
| [chat.md](chat.md) | `/api/v1/chat` | Conversations, messages, reactions, pins, media upload, communities, events, meetings |
| [calls.md](calls.md) | `/api/v1/calls` | Call lifecycle, participants, history, LiveKit |
| [stories.md](stories.md) | `/api/v1/stories` | Feed, discover, create, view, viewers |
| [notifications.md](notifications.md) | `/api/v1/notifications` | In-app notification inbox |
| [apk.md](apk.md) | `/api/v1/apk` | Update check, download, upload |
| [translate.md](translate.md) | `/api/v1/translate` | Text translation proxy |
| [keys.md](keys.md) | `/api/v1/keys` | Message-key formula for client-side encryption |
| [admin.md](admin.md) | `/api/v1/admin` | Stats, moderation, settings, broadcast, audit logs |
| [realtime.md](realtime.md) | `/ws/chat`, `/ws/call` | Socket.IO events (both namespaces) |
| [push-notifications.md](push-notifications.md) | — | FCM payload shapes the client must handle |
| [enums.md](enums.md) | — | Every enum + the full User object |

---

## Base URL

```
https://<host>/api/v1
```

Health probe (no auth): `GET /health` → `200 {success, pid, uptime, checks:{mongo, redis}}`, or `503` when Mongo/Redis are down.

---

## Authentication

All protected endpoints (marked 🔒 throughout these docs) need:

```http
Authorization: Bearer <jwt>
```

The JWT is returned by `/auth/register`, `/auth/login`, `/auth/google` and `/auth/phone/verify-otp`. It expires in **7 days** and carries `{ id, deviceId, tokenVersion }`.

### Session revocation

If you send a `device` object at login, the token is bound to that device session. When that session is revoked (logout elsewhere, admin force-logout), **every** request returns:

```json
{ "success": false, "code": "SESSION_REVOKED", "message": "This session has been logged out" }
```

→ On `code: "SESSION_REVOKED"`, wipe local credentials and send the user to the login screen. Live sockets also receive a `session_revoked` event and are disconnected immediately.

---

## Response envelope

**Success**

```json
{ "success": true, "data": { } }
```

Some endpoints return `message` instead of `data` (pure actions), or extra top-level keys (`token`, `total`, `pagination`, `incoming`/`outgoing`). Each endpoint documents its exact shape.

**Failure** — always this shape:

```json
{ "success": false, "message": "Human readable reason" }
```

Two endpoints add a machine-readable `code`: `SESSION_REVOKED` (401, any endpoint) and `PHONE_ALREADY_LINKED` (409, `PATCH /auth/`).

---

## Request validation

Every route validates its body, query string and path parameters before the handler runs. The rules are the field tables in each module doc — this section is the behaviour they all share.

**Validation failures** return `400` with the standard envelope plus an `errors` array. Every bad field is reported in one response, not one at a time; `message` repeats the first error so a client that only reads `message` still shows something useful.

```json
{
  "success": false,
  "message": "password must be at least 6 characters",
  "errors": [
    { "field": "password", "message": "password must be at least 6 characters" },
    { "field": "device.platform", "message": "device.platform must be one of: ios, android, web, other" },
    { "field": "participantIds[2]", "message": "participantIds[2] must be a valid id" }
  ]
}
```

`field` uses dotted paths for nested objects and `[i]` for array positions.

**Rules that apply everywhere:**

* **Unknown fields are dropped.** Anything not listed in an endpoint's field table is discarded before the handler sees it — sending `role` or `isPremium` to a profile update does nothing. Extra keys are never an error, so a newer client can send fields an older server ignores.
* **Ids must be well-formed.** Any `:id`, `:userId` or `:chatId` path segment, and any id in a body, must be a 24-character hex ObjectId. A malformed id is a `400`, not a `500` or a `404`.
* **Types are coerced, then checked.** Query strings arrive as text: `?limit=20` becomes a number, `?includeArchived=true` a boolean. In a JSON body, send real types — a string where a boolean belongs is rejected unless it is exactly `"true"`/`"false"`/`"1"`/`"0"`.
* **Objects are required where an object is expected.** A query or body value shaped like `{"$ne": null}` is rejected rather than reaching the database.
* **Pagination clamps, it does not fail.** `limit` above an endpoint's maximum is silently reduced to that maximum. A non-numeric `limit` is still a `400`.
* **Strings are trimmed** (except passwords and tokens) and length-capped. An empty string on an optional field means "clear this value"; on a required field it is a missing-value error.
* **Bodies are capped at 256 KB.** A larger body gets `413`, and malformed JSON gets `400` with `"Request body is not valid JSON"`.

> Socket.IO event payloads (see [realtime.md](realtime.md)) are **not** covered by this layer — they are validated inside their own handlers.

---

## Status codes

| Code | Meaning |
|---|---|
| `200` | OK |
| `201` | Created |
| `400` | Bad/missing input |
| `401` | Missing / invalid / revoked token |
| `403` | Authenticated but not allowed (not a member, blocked, privacy, feature off) |
| `404` | Not found (**also used to hide blocked users**) |
| `409` | Conflict (`code: "PHONE_ALREADY_LINKED"`) |
| `410` | Gone (joining a call that already ended) |
| `429` | Rate limited — see `Retry-After` header (seconds) |
| `500` | Server error |
| `502 / 503` | Upstream microservice error/unavailable (translate only) |

---

## Rate limiting

Limits are per **IP** unless stated otherwise. On `429` you get a `Retry-After` header in seconds and:

```json
{ "success": false, "message": "Too many requests, please try again later." }
```

| Bucket | Limit | Endpoints |
|---|---|---|
| Auth | 10 / min | `register`, `login`, `google` |
| OTP send | 5 / 15 min | `phone/send-otp`, `forgot-password` |
| OTP verify | 10 / 15 min | `phone/verify-otp`, `reset-password` |
| Send message | 120 / min | `POST /chat/conversations/:id/messages` |
| Media upload sign | 30 / min | `POST /chat/media/upload` |
| Chat writes | 60 / min | create/delete conversation, create community/event/meeting |
| User search | 60 / min | `GET /users/search` |
| Contact match | 10 / 5 min | `POST /users/contacts/match` |
| Friend requests | 60 / 5 min | `POST /users/friend-requests` |
| Story create | 30 / 5 min | `POST /stories` |
| Story view | 300 / min | `POST /stories/:id/view` |
| Nearby heartbeat | 30 / min | `POST /users/nearby/heartbeat` |
| Nearby ping | 20 / 5 min | `POST /users/nearby/ping` |
| Nearby settings | 20 / 5 min **per user** | `PATCH /users/nearby/settings` |
| Nearby connect request | **5 / day per user** (refunded on failure) | `POST /users/nearby/request` |

> If Redis is unavailable the limiter fails **open** — requests pass through rather than being rejected.

---

## IDs & dates

* All ids are 24-char Mongo ObjectId hex strings.
* All dates are ISO-8601 UTC strings (`2026-08-14T09:12:33.000Z`).

---

## Known inconsistencies to code around

These are real, live in production, and will each cost you an afternoon if you don't know about them:

1. **`name`/`imageUrl` vs `title`/`image`** — `GET /chat/conversations` returns `name`/`imageUrl`; `GET /chat/conversations/:id` returns `title`/`image`. Same entity, different keys. Normalise in your model layer.
2. **`before` vs `after` pagination** — in `GET /chat/conversations/:id/messages`, `before` takes an **ISO timestamp** but `after` takes a **message id**.
3. **Community `:id` means two different things** — `/communities/:id/join|leave|members|preview` takes the **chat id**; `/communities/:id/events` takes the **space id**.
4. **Community chats are not in `/conversations`** — they only come from `GET /chat/communities`.
5. **Visibility values are case-sensitive** — `"Everyone"` / `"Contacts"` / `"Nobody"`, never lowercase.
6. **`404` can mean "blocked"** — `GET /users/:id` and the story endpoints return `404` when either party has blocked the other, not just when the record is gone.
7. **FCM `data` values are always strings** — numbers and objects are JSON-stringified before sending.

---

## Integration checklist

1. **Login** — send a stable `device.deviceId` (generate once per install, persist it). See [auth.md](auth.md#the-device-object).
2. **Push** — `PUT /auth/fcm-token` on app start and on every Firebase token refresh.
3. **Sockets** — connect both namespaces after login; reconnect with a fresh token after any `401`. See [realtime.md](realtime.md).
4. **Session revocation** — handle `code: "SESSION_REVOKED"` (REST) and `session_revoked` (socket) through the same logout path.
5. **Rate limits** — respect `Retry-After` on `429`; back off rather than retrying tight.
6. **Media** — always `POST /chat/media/upload` → upload to the provider → send the returned `mediaUrl`. See [chat.md](chat.md#media-upload).
7. **Update gate** — `GET /apk/info?versionCode=<yours>` on start; honour `isForceUpdate`. See [apk.md](apk.md).
