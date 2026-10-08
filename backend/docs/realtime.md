# Realtime API — Socket.IO

Namespaces: `/ws/chat` and `/ws/call`

> Shared conventions — auth, error envelope: **[README.md](README.md)**
> REST counterparts: **[chat.md](chat.md)** · **[calls.md](calls.md)**

---

## Connecting

Both namespaces use the **same JWT** as the REST API.

```js
import { io } from 'socket.io-client';

const opts = { auth: { token: jwt }, transports: ['websocket'] };

const chat = io('https://<host>/ws/chat', opts);
const call = io('https://<host>/ws/call', opts);
```

The token may also be sent as an `Authorization: Bearer <jwt>` handshake header.

### Connection errors

| `connect_error` message | Meaning | Client action |
|---|---|---|
| `Authentication required` | No token in the handshake | Send the token |
| `Authentication failed` | Token invalid or expired | Refresh via login |
| `Session revoked` | Device session was logged out | Wipe credentials, go to login |

### Rooms

* You are **automatically** joined to a personal room keyed by your **user id** — that's how direct events (`incoming_call`, `friend_request_received`, `message_delivered`) reach you.
* Join a conversation room explicitly with `join_chat { chatId }` — required for room-scoped events (typing, reactions, read receipts, pins).
* Join a call's signaling room with `join_call_room { callId }`.

### Reconnection

Socket.IO reconnects automatically. On reconnect you must **re-emit `join_chat`** for the conversation you're viewing — room membership is not restored for you.

---

# `/ws/chat`

## Client → server

| Event | Payload | Notes |
|---|---|---|
| `join_chat` | `{ chatId }` | Required before you receive room-scoped events |
| `send_chat_message` | see [below](#send_chat_message) | |
| `edit_message` | `{ messageId, chatId, content }` | Text messages only, own messages only |
| `delete_message` | `{ messageId, chatId, forEveryone }` | |
| `messages_read` | `{ chatId, senderId }` | `senderId` optional |
| `typing` | `{ conversationId }` | `conversationId` = chat id |
| `stop_typing` | `{ conversationId }` | |
| `is_user_online` | `{ userId }` | Subject to the target's `lastSeenVisibility` |

### `send_chat_message`

```js
chat.emit('send_chat_message', {
  chatId: '66d4...',
  type: 'text',                 // see enums.md → message types
  content: 'hey',
  mediaUrl: null,               // from POST /chat/media/upload
  mediaMeta: null,              // { thumbnail, size, duration, mimeType, fileName }
  replyToId: null,
  isDirect: true,               // skips the member lookup for 1:1 chats
  senderName: 'Amit Sharma',    // used as the push notification title for recipients
  clientMessageId: 'local-uuid' // echoed back so you can reconcile optimistic sends
});
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `chatId` | string | ✅ | |
| `type` | enum | ❌ | Default `"text"` |
| `content` | string | ❌ | |
| `mediaUrl` | string | ❌ | Omitting it sends `media: null` |
| `mediaMeta` | object | ❌ | |
| `replyToId` | string | ❌ | |
| `isDirect` | bool | ❌ | Set `true` for 1:1 chats — skips the group member query |
| `senderName` | string | ❌ (send it) | **Without it, recipients' push notifications have no sender name** |
| `clientMessageId` | string | ❌ (send it) | Your local id, echoed in `message_sent` and `receive_chat_message` |

**Prefer this over `POST /chat/conversations/:id/messages`** whenever the socket is connected — REST can't carry `senderName` or `clientMessageId`.

---

## Server → client

| Event | Payload | When |
|---|---|---|
| `message_sent` | full message + `clientMessageId` | Your own send succeeded — swap your optimistic bubble for this |
| `receive_chat_message` | full message + `senderName`, `clientMessageId` | A new message for you |
| `message_delivered` | `{ messageId, receiverId, status: "delivered" }` | A recipient received your message |
| `messages_read` | `{ chatId, readerId }` | Someone read the thread |
| `message_edited` | `{ messageId, chatId, content, edited: true, editedAt }` | |
| `message_deleted` | `{ messageId, chatId, forEveryone }` | `forEveryone: false` goes only to the deleter |
| `message_reaction` | `{ chatId, messageId, userId, emoji }` | `emoji: null` = reaction removed |
| `message_pinned` | `{ chatId, messageId, isPinned, pinnedAt, message }` | |
| `conversation_deleted` | `{ chatId, deletedBy }` | Owner deleted the group — close the screen |
| `user_typing` | `{ conversationId, userId }` | |
| `user_stop_typing` | `{ conversationId, userId }` | |
| `user_online_status` | `{ userId, online }` | Reply to `is_user_online` |
| `friend_request_received` | `{ _id, status, createdAt, sender }` | |
| `friend_request_updated` | `{ _id, status, chatId, responder }` | Your sent request was accepted/rejected |
| `message_error` | `{ error }` | Send/edit/delete failed |
| `chat_error` | `{ chatId, error }` | e.g. `Not a member` on `join_chat` |
| `session_revoked` | `{ deviceId }` | Logged out elsewhere — the socket disconnects right after |

### Delivery model

The server emits over the socket when the recipient is online **and** sends an FCM push to their *other*, offline devices. A device that's currently connected never receives a duplicate push for the same message.

`message_delivered` fires as soon as any of the recipient's devices receives it — socket **or** push.

### Optimistic send flow

```
1. Render the bubble locally with your own clientMessageId, status 'sending'
2. emit('send_chat_message', { ..., clientMessageId })
3. on('message_sent')      → match by clientMessageId, replace with the server message, status 'sent'
   on('message_error')     → mark the bubble failed, offer retry
4. on('message_delivered') → status 'delivered'
5. on('messages_read')     → status 'read'
```

---

# `/ws/call`

## Client → server

| Event | Payload | Notes |
|---|---|---|
| `initiate_call` | `{ chatId, callType, initiatorName }` | Full socket alternative to `POST /calls` — creates the call, joins you to the room, and rings everyone |
| `join_call_room` | `{ callId }` | Emit after `POST /calls/:id/join` — and after `POST /calls` if you started the call over REST, or you get no room events for it |
| `leave_call_room` | `{ callId, status }` | |
| `end_call` | `{ callId, status }` | Ends for everyone |
| `decline_call` | `{ callId }` | |
| `call_ringing` | `{ callId }` | Your device is now visibly ringing — lets the caller show "Ringing…" |
| `invite_to_call` | `{ calleeId, callId, callType, initiatorName }` | Pull someone in; auto-upgrades a 1:1 call to a group call |
| `get_livekit_token` | `{ callId }` | |
| `get_call_history` | `{ limit }` | |
| `get_chat_call_history` | `{ chatId, limit }` | |
| `get_call_by_id` | `{ callId }` | |

## Server → client

| Event | Payload | When |
|---|---|---|
| `call_initiated` | `{ call, participants }` | Your `initiate_call` succeeded |
| `incoming_call` | `{ callId, callType, initiatorId, initiatorName }` | Someone is calling you |
| `call_participant_joined` | `{ callId, userId, participant }` | |
| `call_participant_left` | `{ callId, userId, status }` | |
| `call_participant_disconnected` | `{ callId, userId, reconnectWithinMs }` | Their socket dropped and the call is being **held open** for them. Show "reconnecting", do not tear down |
| `call_declined` | `{ callId, userId }` | |
| `call_ringing` | `{ callId, userId }` | Callee's device is ringing |
| `call_participants_added` | `{ callId, participants }` | |
| `call_ended` | `{ callId, status }` | **Tear down LiveKit and close the call UI.** Delivered exactly once, and not to whoever ended the call |
| `livekit_token` | `{ callId, room, token, url }` | Reply to `get_livekit_token` |
| `call_history` | `{ history: [callDto] }` | |
| `chat_call_history` | `{ chatId, history: [callDto] }` | |
| `call_details` | `{ call: callDto }` | |
| `call_error` | `{ callId?, error }` | |
| `session_revoked` | `{ deviceId }` | |

### `callDto`

⚠️ The socket history/detail events use a **different shape** from the REST call object:

```json
{
  "_id": "66e1...",
  "conversationId": "66d4...",
  "type": "video",
  "scope": "1:1",
  "initiatorId": "66b0...",
  "status": "ended",
  "startedAt": "...",
  "endedAt": "...",
  "durationSeconds": 88,
  "participants": [
    { "_id": "...", "callId": "...", "userId": "...", "status": "left", "joinedAt": "...", "leftAt": "..." }
  ]
}
```

| `callDto` | REST equivalent |
|---|---|
| `conversationId` | `chatId` |
| `type` | `callType` |
| `scope` (`"1:1"` \| `"group"`) | `isGroupCall` (bool) |
| `initiatorId` | `initiatedBy` |
| `durationSeconds` | `duration` |

Pick one source for your call log — mixing REST and socket shapes will bite you.

---

## LiveKit

Media is carried by LiveKit. The **room name is the `callId`**.

```js
call.emit('get_livekit_token', { callId });

call.on('livekit_token', ({ token, url, room }) => {
  // room === callId
  // connect your LiveKit client with (url, token)
});
```

* Tokens are valid **1 hour** and grant publish + subscribe.
* The display name in the room is taken from the **server-side account**, not from anything the client sends.
* `url` is the LiveKit server URL — read it from the event, don't hardcode it.

### Errors

`call_error` with `callId is required for a LiveKit token`, or `LiveKit is not configured (LIVEKIT_API_KEY / LIVEKIT_API_SECRET)` when the server is missing credentials.

---

## Call lifecycle over sockets

**Caller**

```
1. POST /calls  →  emit('join_call_room', { callId })   ← REST does not join you
   or emit('initiate_call')  →  on('call_initiated')    ← joins you for you
2. show outgoing-call UI
3. emit('get_livekit_token')       → connect to LiveKit
4. on('call_ringing')              → "Ringing…"
5. on('call_participant_joined')   → "Connected"
6. emit('end_call')                → teardown
```

**Callee**

```
1. on('incoming_call')  — or a VoIP FCM push if the app was killed
2. emit('call_ringing', { callId })     → tell the caller the UI is up
3. User answers:  POST /calls/:id/join  →  emit('join_call_room')  →  emit('get_livekit_token')
   User rejects:  POST /calls/:id/decline  →  emit('decline_call')
4. on('call_ended')  →  tear down
```

> If the app was killed, the callee gets an **FCM VoIP push** instead of `incoming_call` — see [push-notifications.md](push-notifications.md#incoming-call--high-priority-voip). Connect the socket first, then act.
> On socket disconnect mid-call the server does **not** end the call immediately. Peers get `call_participant_disconnected` with a `reconnectWithinMs` window (15 s by default, `CALL_RECONNECT_GRACE_MS`); rejoining inside it — `POST /calls/:id/join` then `emit('join_call_room')` — cancels the pending leave and peers get `call_participant_joined`. If the window closes, the leave runs as before and peers get `call_participant_left` / `call_ended`.
>
> This is what lets a web client survive a page reload: persist the `callId`, check `GET /calls/:id` on load, and rejoin if the call is not in a terminal status.

---

## Presence

* Presence is tracked in Redis with a 30 s heartbeat and a 90 s staleness window, shared across all server workers.
* `is_user_online` respects the target's `lastSeenVisibility` — a `Nobody` setting always returns `online: false`, regardless of reality.
* On a graceful server shutdown, presence entries are cleared immediately rather than aging out.
