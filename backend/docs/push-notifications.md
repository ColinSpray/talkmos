# Push Notifications (FCM)

> Shared conventions: **[README.md](README.md)** · Socket delivery: **[realtime.md](realtime.md)**

Every payload below is **data-only** unless noted — the client renders the UI.

---

## Setup

1. Obtain the Firebase token on the device.
2. Send it at login inside the [`device` object](auth.md#the-device-object), **and** call [`PUT /auth/fcm-token`](auth.md#put-authfcm-token) on app start and on every token refresh.
3. Tokens are stored **per device session**, so one account can receive pushes on up to 15 devices.

---

## Two universal rules

### 1. All `data` values are strings

Numbers, booleans and objects are JSON-stringified before sending. Parse accordingly:

```dart
final callId   = data['callId'];                     // already a String
final metadata = jsonDecode(data['metadata'] ?? '{}'); // objects need decoding
```

### 2. Connected devices don't get duplicates

For chat messages and calls, the server checks Redis presence first: it emits over the socket to connected devices and pushes **only to that user's other, offline devices**. A device with a live socket will not receive a push for the same event.

---

## Chat message

Sent to offline devices when a new message arrives.

```json
{
  "chatId": "66d4...",
  "senderId": "66b1...",
  "messageId": "66f0...",
  "senderName": "riya kapoor",
  "title": "riya kapoor",
  "body": "Sent you a message"
}
```

| Field | Notes |
|---|---|
| `senderName` | `""` when the recipient has `notificationPreviewEnabled: false` |
| `title` | `"New message"` when preview is disabled |
| `body` | Never the message text — see below |

### Body text by message type

The body is always a **generic label**, never message content:

| Message type | Body |
|---|---|
| `text` | `Sent you a message` |
| `image` | `Sent a photo` |
| `video` | `Sent a video` |
| `audio` | `Sent an audio message` |
| `voice` | `Sent a voice message` |
| `file` | `Sent a document` |
| `contact` | `Shared a contact` |
| `location` | `Shared their location` |
| `gif` | `Sent a GIF` |
| `sticker` | `Sent a sticker` |
| anything else | `Sent a <type> attachment` |

**Tap action:** open chat `chatId`, scroll to `messageId`.

> Muted chats (`preferences.isMuted`) are **not** filtered server-side — check the user's local mute state before displaying, or accept that muted chats still notify.

---

## Incoming call — high priority, VoIP

```json
{
  "type": "call",
  "callId": "66e1...",
  "callType": "audio",
  "initiatorId": "66b0...",
  "initiatorName": "amit sharma"
}
```

**Transport settings**

| Platform | Settings |
|---|---|
| Android | `priority: high`, TTL **45 s** |
| iOS | `apns-push-type: voip`, `apns-priority: 10`, `apns-expiration: 45`, `content-available: 1`, `sound: default`, `category: INCOMING_CALL` |

**Client action:** wake the app and show the native incoming-call UI — CallKit on iOS, a full-screen intent (e.g. `flutter_callkit_incoming`) on Android. Then connect the socket and follow the callee flow in [realtime.md](realtime.md#call-lifecycle-over-sockets).

> Deliberately **data-only** (no `notification` key) so the background handler fires and you control the UI. Don't add a notification block client-side.
> The 45 s TTL means a push that can't be delivered in time is dropped rather than arriving as a stale ring.

---

## Call cancelled / ended

```json
{ "type": "call_ended", "callId": "66e1..." }
```

| Platform | Settings |
|---|---|
| Android | `priority: high`, TTL 45 s |
| iOS | `apns-push-type: background`, `apns-priority: 10`, `content-available: 1` |

**Client action:** dismiss the incoming-call UI / end the CallKit session for `callId`. Sent when the caller hangs up before you answer.

---

## Nearby locate — **silent**

```json
{ "type": "nearby_locate" }
```

| Platform | Settings |
|---|---|
| Android | `priority: high`, TTL **120 s** |
| iOS | `apns-push-type: background`, **`apns-priority: 5`**, `content-available: 1` — no alert, no sound, no badge |

**Client action:**

1. Check the user still has Nearby enabled locally. If not, **do nothing**.
2. Read the current coarse position.
3. `POST /users/nearby/ping` with `{ lat, lng }`.

> ⚠️ **Never render anything visible for this.** The user consented to being discoverable, not to being notified. Adding an alert, sound or badge here would break that.
> Rate-limited server-side to one request per user per 5 minutes.
> Sent to **every** device on the account — first to answer wins, and duplicate pings are harmless.

---

## Friend request

```json
{ "type": "friend_request", "friendRequestId": "66c2...", "senderId": "66b1..." }
```

Title `New Friend Request`, body `<name> sent you a friend request`.
Also written to the in-app inbox ([notifications.md](notifications.md)).

**Tap action:** open the Friend Requests screen.

> Nearby-sourced requests carry the same `type` — check the inbox row's `metadata.source === "nearby"` to distinguish them and show the attached message.

---

## Friend request accepted

```json
{ "type": "friend_request_accepted", "friendRequestId": "66c2...", "responderId": "66b1..." }
```

Title `Friend Request Accepted`, body `<name> accepted your friend request`.

**Tap action:** open the newly created chat (`chatId` comes from `PUT /users/friend-requests/:id` or `GET /users/friends`).

---

## Admin broadcast

```json
{ "type": "system", "imageUrl": "https://...", "title": "New feature", "body": "Nearby is live!" }
```

Unlike the others this one **also carries a real `notification` block** (`aps.alert` on iOS, `priority: high` on Android), so the OS may display it directly. Handle both paths — foreground data handler and OS-rendered notification — to avoid showing it twice.

**Tap action:** open the in-app notification inbox.

---

## Handling matrix

| `type` | Visible? | Foreground | Background | Killed |
|---|---|---|---|---|
| *(none — chat message)* | ✅ | Suppress if the chat is open | Show notification | Show notification |
| `call` | ✅ full-screen | Show in-call UI | Full-screen intent / CallKit | Wake + CallKit |
| `call_ended` | ❌ | Dismiss call UI | Dismiss call UI | Dismiss |
| `nearby_locate` | ❌ **never** | Ping position | Ping position | Ping position |
| `friend_request` | ✅ | In-app banner | Show notification | Show notification |
| `friend_request_accepted` | ✅ | In-app banner | Show notification | Show notification |
| `system` | ✅ | In-app banner | OS-rendered | OS-rendered |

---

## Delivery pipeline

Push jobs are published to RabbitMQ and sent by a separate Go worker — the API request never waits on Firebase.

**What this means for you:**

* A `200` from an API call means the push was **queued**, not delivered.
* Delivery is typically sub-second but is **not** synchronous — don't gate UI on it.
* Failed jobs retry after 30 s, up to 5 times, then land in a dead-letter queue.
* **Exceptions:** call pushes (`call`, `call_ended`), `nearby_locate`, and admin broadcasts are sent **directly** to Firebase, bypassing the queue — latency (or, for broadcasts, batching) matters more there than durability. Only chat/friend-request style pushes go through RabbitMQ.
