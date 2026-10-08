# Calls API

Base path: `/api/v1/calls`

> Shared conventions — auth header, error envelope, status codes: **[README.md](README.md)**
> **All endpoints in this module require 🔒 `Authorization: Bearer <jwt>`.**
> Real-time call signaling lives in **[realtime.md](realtime.md#wscall)**.

---

## Routes at a glance

| Method | Path | Purpose |
|---|---|---|
| `POST` | [`/`](#post-calls) | Start a call |
| `GET` | [`/:id`](#get-callsid) | Call detail + participants |
| `POST` | [`/:id/join`](#post-callsidjoin) | Answer / join |
| `POST` | [`/:id/decline`](#post-callsiddecline) | Reject |
| `POST` | [`/:id/leave`](#post-callsidleave) | Hang up (others may continue) |
| `POST` | [`/:id/end`](#post-callsidend) | End for everyone |
| `POST` | [`/:id/participants`](#post-callsidparticipants) | Add people to a group call |
| `GET` | [`/me/history`](#get-callsmehistorylimit50) | My call log |
| `GET` | [`/chat/:chatId`](#get-callschatchatidlimit30) | Call log for one conversation |

> **Route order:** `/me/history` and `/chat/:chatId` are registered before `/:id`, so they're never captured by it.

---

## How calling works

Media is carried by **LiveKit**. This API only handles signaling and call records — it never touches audio/video.

```
Caller                                            Callee
──────────────────────────────────────────────────────────────────────────
POST /calls  ──────────────────────────────────►  incoming_call  (socket)
                                                  …or VoIP FCM push if offline
socket: join_call_room { callId }                 POST /calls/:id/join
socket: get_livekit_token { callId }              socket: join_call_room { callId }
                                                  socket: get_livekit_token { callId }
                                                  connect to LiveKit (room = callId)
        ◄─────── call_participant_joined ───────►
…
POST /calls/:id/end  ──────────────────────────►  call_ended (socket)
                                                  + call_ended FCM push if offline
```

**Key point:** the LiveKit **room name is the `callId`**, so both sides join the same session. Get the token over the socket (`get_livekit_token`), not over REST.

**Callers must join the room too.** `POST /calls` creates the call over REST, which cannot put your socket in the signaling room — emit `join_call_room { callId }` right after it returns, or you receive none of the room events for your own call. `initiate_call` over the socket joins you automatically; this step is only for the REST path.

**`call_ended` arrives exactly once** per participant, emitted from the transition into a terminal status. Whichever teardown path caused it — leave, end, decline, disconnect — only that one announces it, and the actor who triggered it is not sent their own event.

**Push vs socket:** the server emits `incoming_call` over the socket *and* sends a VoIP-style FCM push **only if the callee isn't connected** to `/ws/call`. A connected device never gets a duplicate push.

---

## `POST /calls`

Start a call in an existing conversation.

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `chatId` | string | ✅ | Direct chat → 1:1 call; group/community → group call |
| `callType` | `audio` \| `video` | ✅ | |
| `calleeName` | string | ❌ | Your own display name, shown on the callee's incoming-call UI |

```json
{ "chatId": "66d4...", "callType": "video", "calleeName": "Amit Sharma" }
```

### Response `201`

```json
{
  "success": true,
  "data": {
    "call": {
      "_id": "66e1...",
      "chatId": "66d4...",
      "initiatedBy": "66b0...",
      "callType": "video",
      "isGroupCall": false,
      "status": "ringing",
      "roomId": "3f2a9c1e-...",
      "startedAt": "2026-08-14T09:12:33.000Z",
      "endedAt": null,
      "endedBy": null,
      "duration": 0,
      "createdAt": "2026-08-14T09:12:33.000Z"
    },
    "participants": [
      {
        "_id": "66e2...", "callId": "66e1...",
        "userId": { "_id": "66b0...", "name": "amit sharma", "avatarUrl": "https://..." },
        "status": "joined", "joinedAt": "2026-08-14T09:12:33.000Z", "leftAt": null
      },
      {
        "_id": "66e3...", "callId": "66e1...",
        "userId": { "_id": "66b1...", "name": "riya kapoor", "avatarUrl": "https://..." },
        "status": "ringing", "joinedAt": null, "leftAt": null
      }
    ]
  }
}
```

> The caller is **auto-joined** (`status: "joined"`). Don't call `/join` for yourself.
> Ignore `roomId` — the LiveKit room name is the `_id`, not `roomId`.

### Errors

| Code | Message |
|---|---|
| `400` | `callType must be "audio" or "video"` · `Chat not found` |
| `403` | `Not a member of this chat` · `You can only call friends or public accounts` |

---

## `GET /calls/:id`

### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "66e1...", "chatId": "66d4...", "initiatedBy": "66b0...",
    "callType": "video", "isGroupCall": false, "status": "ongoing",
    "roomId": "3f2a9c1e-...", "startedAt": "...", "endedAt": null,
    "endedBy": null, "duration": 0, "createdAt": "...",
    "participants": [ { "_id", "callId", "userId": { "_id", "name", "avatarUrl" }, "status", "joinedAt", "leftAt" } ]
  }
}
```

### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |
| `404` | `Call not found` |

---

## `POST /calls/:id/join`

Answer an incoming call, or rejoin one you dropped from. No body. **Idempotent** — joining twice is safe.

### Response `200`

```json
{
  "success": true,
  "data": {
    "call": { "...", "status": "ongoing" },
    "participant": { "_id", "callId", "userId", "status": "joined", "joinedAt": "...", "leftAt": null }
  }
}
```

Flips the call from `ringing` to `ongoing` on the first join. After this succeeds, emit `join_call_room { callId }` on the socket, then `get_livekit_token { callId }`.

### Errors

| Code | Message | Client action |
|---|---|---|
| **`410`** | `This call has already ended` | **Dismiss the incoming-call UI** — the caller hung up before you answered |
| `403` | `Not a member of this chat` | |
| `404` | `Call not found` | |

---

## `POST /calls/:id/decline`

Reject an incoming call. No body.

### Response `200`

```json
{
  "success": true,
  "data": {
    "call": { "...", "status": "declined" },
    "participant": { "...", "status": "declined" }
  }
}
```

> For a **1:1** call this ends the whole call (`status: "declined"`). For a **group** call only your own participant row changes — the call continues for everyone else.

### Errors

| Code | Message |
|---|---|
| `400` | `You were not invited to this call` |
| `404` | `Call not found` |

---

## `POST /calls/:id/leave`

Hang up your own leg. No body.

### Response `200`

```json
{
  "success": true,
  "data": {
    "call": { "...", "status": "ended" },
    "participant": { "...", "status": "left", "leftAt": "..." }
  }
}
```

The call **auto-ends** when nobody is left, or when only one person remains with no outstanding invites. Check `data.call.status` — if it's `ended` or `missed`, tear down your LiveKit connection.

### Errors

| Code | Message |
|---|---|
| `400` | `You are not currently in this call` |
| `404` | `Call not found` |

> On socket disconnect the server runs leave for you automatically, so peers still get `call_participant_left` / `call_ended`.

---

## `POST /calls/:id/end`

End the call for everyone.

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `status` | `failed` | ❌ | Only send this to report a **technical failure**. Omit for a normal hang-up. |

### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "66e1...", "status": "ended",
    "endedAt": "2026-08-14T09:14:01.000Z", "endedBy": "66b0...",
    "duration": 88, "...": "..."
  }
}
```

> **If nobody besides the initiator ever joined, the stored status becomes `missed`, not `ended`.** Read `data.status` back rather than assuming. `duration` is in seconds.
> Calling this on an already-ended call is a no-op that returns `200` with the existing record.

### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |
| `404` | `Call not found` |

---

## `POST /calls/:id/participants`

Add people to a **group** call. All must be members of the underlying chat.

### Request

```json
{ "userIds": ["66b2...", "66b3..."] }
```

### Response `201`

```json
{
  "success": true,
  "data": [
    { "_id", "callId", "userId", "status": "ringing", "joinedAt": null, "leftAt": null }
  ]
}
```

Broadcasts `call_participants_added` to the call room. Re-adding someone who declined or missed puts them back in `ringing`.

### Errors

| Code | Message |
|---|---|
| `400` | `userIds must be a non-empty array` · `Cannot add participants to a 1:1 call` · `This call has already ended` |
| `403` | `Not a member of this chat` (yours or theirs) |
| `404` | `Call not found` |

> To pull someone into a **1:1** call instead, use the socket event `invite_to_call` — it upgrades the call to a group call automatically.

---

## `GET /calls/me/history?limit=50`

Your personal call log. `limit` default 50, **max 100**.

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "call": {
        "_id": "66e1...", "chatId": "66d4...",
        "initiatedBy": { "_id": "66b0...", "name": "amit sharma", "avatarUrl": "https://..." },
        "callType": "video", "isGroupCall": false, "status": "missed",
        "startedAt": "...", "endedAt": "...", "duration": 0,
        "participants": [ { "_id", "callId", "userId": { "_id", "name", "avatarUrl" }, "status", "joinedAt", "leftAt" } ]
      },
      "myStatus": "missed",
      "joinedAt": null,
      "leftAt": null
    }
  ]
}
```

Newest first.

**Rendering the log:**

* **Incoming vs outgoing** — compare `call.initiatedBy._id` with your own user id.
* **Icon / colour** — use `myStatus`: `missed` (red), `declined`, `joined`, `left`.
* **Duration** — `call.duration` in seconds; `0` for missed/declined.

---

## `GET /calls/chat/:chatId?limit=30`

Call history for one conversation. `limit` default 30, **max 100**. Newest first.

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66e1...", "chatId": "66d4...",
      "initiatedBy": { "_id": "...", "name": "...", "avatarUrl": "..." },
      "callType": "audio", "isGroupCall": false, "status": "ended",
      "startedAt": "...", "endedAt": "...", "duration": 88,
      "participants": [ "…" ]
    }
  ]
}
```

### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |

---

## Status reference

### `call.status`

| Value | Meaning |
|---|---|
| `ringing` | Created, waiting for someone to answer |
| `ongoing` | At least one callee joined |
| `ended` | Completed normally |
| `missed` | Nobody but the initiator ever joined |
| `declined` | Callee explicitly rejected (1:1) |
| `failed` | Technical failure (reported by the client via `POST /:id/end` with `status: "failed"`) |

### `participant.status`

| Value | Meaning |
|---|---|
| `invited` | Added but not yet notified |
| `ringing` | Actively being notified |
| `joined` | Currently connected |
| `declined` | Explicitly rejected |
| `missed` | Never responded before the call ended |
| `left` | Joined, then disconnected |
| `busy` | Was already on another call |
