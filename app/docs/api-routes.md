# Talkmos API routes

Every backend route the app calls, what each returns, and how much comes back.

Derived from `lib/core/config/api_endpoints.dart` and the service classes that
call it, then **verified against a live backend** on 2026-07-30
(`http://192.168.1.33:5000`). Measured sizes and counts below are from that
instance and reflect its data, not a general expectation.

Only **read-only** routes were called. Every `POST`/`PATCH`/`PUT`/`DELETE` is
documented from the code alone — calling them would have mutated or destroyed
real data.

> ### Routes that 404 on the live backend
>
> Seven declared routes do not exist server-side. Four of them **the app calls at
> runtime**, so those features are broken, not merely unused:
>
> | Route | Called by | Status |
> | --- | --- | --- |
> | `GET /chat/dashboard` | `ChatService.getDashboard()` | **404 — live call fails** |
> | `GET /profile/devices` | `ProfileService.getDevices()` | **404 — live call fails** |
> | `PATCH /profile` | `ProfileService.updateProfile()` | **404 — path missing** |
> | `PATCH /profile/settings` | `ProfileService.updateSettings()` | **404 — path missing** |
>
> Profile edits and the device list cannot be working against this backend. The
> `/profile` prefix answers on none of its paths, which suggests the router is
> mounted elsewhere or not at all rather than four separate omissions.
>
> **Deleted from the client:** `homeSummary`, `homeRecent` and the now-orphaned
> `homeUrl` prefix — 404, and no call site anywhere in `lib/`.
>
> **Kept:** `POST /chat/meetings` (`ChatService.createMeeting`). `GET` on that
> path 404s, but the client only ever POSTs there and writes were not probed, so
> there is no evidence the route is absent. Nothing in the app calls
> `createMeeting`, so it is unreachable either way — dead code rather than a
> broken integration.

**Base URL** comes from `BACKEND_URL` in `.env`; everything below hangs off
`$BACKEND_URL/api/v1`. Prefixes are in `ApiConfig`:

| Prefix | Path |
| --- | --- |
| `authUrl` | `/auth` |
| `callsUrl` | `/calls` |
| `chatUrl` | `/chat` |
| `homeUrl` | `/home` |
| `profileUrl` | `/profile` |
| `storyUrl` | `/stories` |
| `friendUrl` | `/friends` |
| `userSearchUrl` | `/users` |

**Envelope.** REST responses are unwrapped as `{ success: bool, data: …, message: String? }`.
Clients treat `success != true` or a non-2xx status as a failure and throw
`body['message']`.

**Volume column.** "1 object" means a single JSON object; a count means a list
whose length is bounded by the stated limit; "unbounded" means the server decides
and the client does not page.

---

## Auth — `/auth`

| Method | Path | Returns | Volume |
| --- | --- | --- | --- |
| POST | `/register` | `UserModel` + token | 1 object |
| POST | `/login` | `UserModel` + token | 1 object |
| GET | `/` | `UserModel` for the bearer token | 1 object |
| PATCH | `/` | updated `UserModel` | 1 object |
| POST | `/forgot-password` | ack only | — |
| POST | `/reset-password` | ack only | — |
| PUT | `/fcm-token` | `bool` ok | — |
| POST | `/google` | `GoogleAuthResult` (user + token + `isNewUser`) | 1 object |
| POST | `/phone/send-otp` | request id / `String?` | — |
| POST | `/phone/verify-otp` | `(isNewUser, UserModel)` | 1 object |

`UserModel` carries: `id`, `name`, `email?`, `phone?`, `username?`, `avatarUrl?`,
`bio?`, `location?`, `status?`, `isPremium`, `isVerified`, `lastSeenAt?`,
`createdAt?`.

## Chat — `/chat`

### Conversations

| Method | Path | Returns | Volume |
| --- | --- | --- | --- |
| GET | `/dashboard` | dashboard blob | 1 object |
| GET | `/conversations` | `RecentChat[]` | unbounded |
| GET | `/conversations?archived=true` | `RecentChat[]` | unbounded |
| POST | `/conversations` | created conversation | 1 object |
| GET | `/conversations/:id` | conversation detail incl. members | 1 object |
| PATCH | `/conversations/:id` | updated conversation | 1 object |
| PATCH | `/conversations/:id/permissions` | updated permissions | 1 object |
| PATCH | `/conversations/:id/preferences` | updated preferences | 1 object |
| PATCH | `/conversations/:id/read` | ack | — |
| DELETE | `/conversations/:id/leave` | ack | — |
| POST | `/conversations/:id/members` | ack | — |
| DELETE | `/conversations/:id/members/:userId` | ack | — |
| GET | `/conversations/:id/pinned-messages` | pinned `ChatMessageModel[]` | unbounded |

`getConversations` is the heaviest routine call — the whole chat list, with each
row's last-message preview, unread count and member list, and **no limit
parameter**. Previews are decrypted client-side on arrival.

### Messages

| Method | Path | Returns | Volume |
| --- | --- | --- | --- |
| GET | `/conversations/:id/messages` | `ChatMessageModel[]`, oldest first | **≤ 50** (`limit`) |
| POST | `/conversations/:id/messages` | the created message | 1 object |
| DELETE | `/messages/:id` | ack | — |
| POST | `/messages/:id/react` | updated reactions | 1 object |
| POST | `/messages/:id/star` | updated message | 1 object |
| POST | `/messages/:id/pin` | updated message | 1 object |
| POST | `/messages/:id/deliver` | ack | — |
| GET | `/conversations/:id/shared-media` | `SharedMediaPage` | **≤ 30** (`limit`) |
| POST | `/media/upload` | uploaded media URL + meta | 1 object |

Query parameters on `GET …/messages`:

- `limit` — page size, default **50** (`ChatProvider._pageSize`).
- `before` — ISO-8601 timestamp; pages **backward** for "load older", anchored on
  the oldest loaded message's `createdAt`.
- `after` — **message id**; asks only for what arrived after a message the client
  already holds. Sent on entering a chat that has cached history, so the common
  case (nothing new) costs a near-empty response instead of a full page.

`before` and `after` are opposites and are not sent together.

> **Measured: this backend ignores `after`.** With 10 messages in a chat,
> `?limit=50` and `?limit=50&after=<newest id>` both returned **all 10**. The
> client handles that safely — `_mergeNewer` keys by id, so the result is
> correct — but the round trip saves nothing until the server implements it.
> `before` *is* honoured: `?before=<oldest createdAt>` correctly returned 0.

`ChatMessageModel` carries: `id`, `chatId`, `senderId`, `senderName`,
`senderAvatarUrl`, `messageType` (text/image/video/audio/voice/file/gif/sticker/
location/contact/system), `content`, `media`, `mentions`, `replyTo?`, `forwarded`,
`edited`, `status`, `isPinned`, `reactions`, `deletedForEveryone`, `deletedForMe`,
`createdAt`, `updatedAt`. Content is **encrypted on the wire** and decrypted
client-side; a full page runs through `ChatEncryption.decryptAll`, which moves to
an isolate above a threshold.

### Communities & meetings

| Method | Path | Returns | Volume |
| --- | --- | --- | --- |
| GET | `/communities` | community list (`?category`) | unbounded |
| POST | `/communities` | created community | 1 object |
| POST | `/communities/:id/join` | ack | — |
| DELETE | `/communities/:id/leave` | ack | — |
| GET | `/communities/:id/members` | member list | unbounded |
| GET | `/communities/:id/events` | event list | unbounded |
| POST | `/meetings` | created meeting | 1 object — untested, unreachable |

## Profile — `/profile`

| Method | Path | Returns | Volume |
| --- | --- | --- | --- |
| PATCH | `/` | updated profile | 1 object |
| PATCH | `/settings` | updated settings | 1 object |
| GET | `/devices` | `DeviceModel[]` | unbounded |
| DELETE | `/devices/:id` | `bool` ok | — |
| POST | `/subscription` | subscription record | 1 object |

## Users & friends

| Method | Path | Returns | Volume |
| --- | --- | --- | --- |
| GET | `/users/search?q=` | matching users | unbounded — 2.2 KB for `q=a` |
| GET | `/users/friends` | friend list | unbounded |
| POST | `/users/match-contacts` | users matching submitted phone numbers | one per match |
| GET | `/users/blocked` | blocked users | unbounded |
| POST | `/users/block/:id` | ack | — |
| POST | `/users/unblock/:id` | ack | — |
| POST | `/friends/requests` | ack | — |
| GET | `/friends/requests/pending` | `{ sent: [], received: [] }` | unbounded |
| PUT | `/friends/requests/:id` | ack | — |

`match-contacts` **uploads** the device's phone numbers — the one route where
request size can exceed response size, and it scales with the address book.

## Stories — `/stories`

| Method | Path | Returns | Volume |
| --- | --- | --- | --- |
| GET | `/feed` | `StoryGroupModel[]` (grouped per author) | unbounded |
| GET | `/discover?category=` | `StoryModel[]` | unbounded |
| POST | `/` | created `StoryModel` | 1 object |
| POST | `/:id/view` | `bool` ok | — |
| DELETE | `/:id` | `bool` ok | — |
| GET | `/:id/views` | viewer list | unbounded |

## System

| Method | Path | Returns | Volume |
| --- | --- | --- | --- |
| GET | apk info (`?versionCode`) | `AppUpdateInfo?` | 1 object |
| GET | apk download | binary APK | file |

---

## Socket.IO

Real-time traffic bypasses REST entirely and connects to `BACKEND_URL`. Two
namespaces are used: chat (`SocketService`) and calls (`CallSignalingService`).

Messages arrive over the socket as single objects — the REST message route is for
history, not for live delivery.

Chat events consumed: `message_received`, `message_sent`, `user_typing`,
`user_stop_typing`, `message_status_changed`, `messages_read`,
`user_online_status`, `message_deleted`, `message_edited`, `message_pinned`,
`message_reacted`.

Call signalling emits `get_call_history` with `limit` — default **50**
(`_historyLimit`).

---

## Real responses

Captured from the live backend on 2026-07-30. **Values are redacted** — names,
emails, phone numbers, avatars and FCM tokens belong to real accounts, including
other people's, and do not belong in a repo. Field names, types, nesting and
byte counts are exactly as returned.

### `GET /auth/`

the signed-in user — 2311 B on the wire

```json
{
  "_id": "<id>",
  "name": "<redacted>",
  "email": "<redacted>",
  "avatarUrl": "<url>",
  "bio": "",
  "location": "",
  "language": "en",
  "status": "offline",
  "notificationsEnabled": true,
  "notificationPreviewEnabled": true,
  "readReceiptsEnabled": true,
  "lastSeenVisibility": "Everyone",
  "profilePhotoVisibility": "Everyone",
  "isBlocked": [],
  "isVerified": true,
  "isPremium": false,
  "premiumExpiry": null,
  "role": "user",
  "fcmToken": "<redacted>",
  "isPublic": false,
  "authProvider": "google",
  "lastSeenAt": "2026-07-27T10:57:32.085Z",
  "devices": [
    {
      "deviceId": "794626478",
      "token": "<redacted>",
      "platform": "android",
      "lastActiveAt": "2026-07-27T12:27:17.312Z",
      "_id": "<id>"
    }
  ],
  "createdAt": "2026-07-27T10:57:32.086Z",
  "updatedAt": "2026-07-30T10:39:17.754Z",
  "__v": 4,
  "phone": "<redacted>",
  "username": "<redacted>"
}
```

### `GET /chat/conversations`

one row of three — 3390 B on the wire

```json
{
  "_id": "<id>",
  "chatType": "direct",
  "spaceId": null,
  "activeCall": null,
  "deletedAt": null,
  "createdAt": "2026-07-27T10:59:47.980Z",
  "permissions": {
    "addMembers": "admins",
    "editInfo": "admins",
    "sendMessages": "everyone"
  },
  "name": "<redacted>",
  "imageUrl": "<url>",
  "lastMessage": {
    "_id": "<id>",
    "chatId": "<id>",
    "senderId": "<id>",
    "messageType": "text",
    "content": "qvhYHSO8SXaSt9iZ:6PTRfWYF0rizTnLvyyQ3eQ==:3yU=",
    "media": null,
    "mentions": [],
    "forwarded": false,
    "edited": false,
    "status": "read",
    "isPinned": false,
    "deletedForEveryone": false,
    "deletedForMe": [],
    "createdAt": "2026-07-30T05:45:03.904Z",
    "updatedAt": "2026-07-30T05:45:28.727Z",
    "senderName": "nitish vishwakarma"
  },
  "lastActivityAt": "2026-07-30T05:45:03.904Z",
  "isPinned": false,
  "isMuted": true,
  "isArchived": false,
  "unreadCount": 0
}
```

### `GET /chat/conversations/:id`

group detail with members — 1591 B on the wire

```json
{
  "_id": "<id>",
  "chatType": "direct",
  "spaceId": null,
  "sender": "<id>",
  "receiver": "<id>",
  "activeCall": null,
  "deletedAt": null,
  "createdAt": "2026-07-27T10:59:47.980Z",
  "updatedAt": "2026-07-30T09:50:04.466Z",
  "__v": 0,
  "permissions": {
    "addMembers": "admins",
    "editInfo": "admins",
    "sendMessages": "everyone"
  },
  "title": "nitish vishwakarma",
  "image": "https://lh3.googleuserco\u2026<truncated>",
  "description": "",
  "role": "member",
  "canSendMessages": true,
  "isPinned": false,
  "isMuted": true,
  "isArchived": false,
  "unreadCount": 0,
  "participants": [
    {
      "userId": {
        "_id": "<id>",
        "name": "<redacted>",
        "avatarUrl": "<url>",
        "status": "offline",
        "lastSeenAt": "2026-07-27T10:57:32.085Z",
        "username": "<redacted>"
      },
      "role": "member"
    }
  ],
  "lastMessage": {
    "_id": "<id>",
    "senderId": {
      "_id": "<id>",
      "name": "<redacted>",
      "avatarUrl": "<url>"
    },
    "content": "qvhYHSO8SXaSt9iZ:6PTRfWYF0rizTnLvyyQ3eQ==:3yU=",
    "type": "text",
    "status": "read",
    "createdAt": "2026-07-30T05:45:03.904Z"
  }
}
```

### `GET …/messages?limit=50`

one message of ten — 6400 B on the wire

```json
{
  "_id": "<id>",
  "chatId": "<id>",
  "senderId": {
    "_id": "<id>",
    "name": "<redacted>",
    "avatarUrl": "<url>"
  },
  "messageType": "text",
  "content": "hi",
  "media": null,
  "mentions": [],
  "replyTo": null,
  "forwarded": false,
  "edited": false,
  "editedAt": null,
  "status": "read",
  "isPinned": false,
  "pinnedAt": null,
  "deletedForEveryone": false,
  "deletedForMe": [],
  "deletedAt": null,
  "createdAt": "2026-07-28T14:47:02.645Z",
  "updatedAt": "2026-07-28T15:08:58.711Z",
  "reactions": [],
  "isStarred": false
}
```

### `GET /users/friends`

one friend of two — 582 B on the wire

```json
{
  "_id": "<id>",
  "name": "<redacted>",
  "email": "<redacted>",
  "avatarUrl": "<url>",
  "status": "offline",
  "isVerified": true,
  "chatId": "<id>"
}
```

### `GET /stories/feed`

one group — 3248 B on the wire

```json
{
  "user": {
    "_id": "<id>",
    "name": "<redacted>",
    "avatarUrl": "<url>",
    "isPublic": false
  },
  "stories": [
    {
      "_id": "<id>",
      "userId": {
        "_id": "<id>",
        "name": "<redacted>",
        "avatarUrl": "<url>",
        "isPublic": false
      },
      "mediaUrl": "https://res.cloudinary.c\u2026<truncated>",
      "mediaType": "image",
      "caption": "",
      "visibility": "friends",
      "category": "Friends",
      "expiresAt": "2026-07-30T11:09:47.513Z",
      "createdAt": "2026-07-29T11:09:47.513Z",
      "updatedAt": "2026-07-29T11:09:47.513Z",
      "__v": 0,
      "viewed": true
    }
  ]
}
```

### `GET /apk/info`

update check — 329 B on the wire

```json
{
  "success": true,
  "available": false,
  "hasUpdate": false,
  "latestVersionName": "1.0.3",
  "latestVersionCode": 4,
  "minRequiredVersionCode": 1,
  "isForceUpdate": false,
  "releaseNotes": "New performance updates and Encrypted Messaging",
  "downloadUrl": "http://192.168.1.33:5000/api/v1/apk/download",
  "fileSize": 0,
  "updatedAt": "2026-07-30T10:53:35.867Z"
}
```


---

## Measured — live backend, 2026-07-30

Account: 3 conversations, 2 friends, 1 story group, 10 messages in the sampled chat.

| Route | Code | Bytes | Items |
| --- | --- | --- | --- |
| `GET /auth/` | 200 | 2311 | 1 object, 28 fields |
| `GET /chat/conversations` | 200 | 3390 | 3 rows |
| `GET /chat/conversations?archivedOnly=true` | 200 | 26 | 0 |
| `GET /chat/conversations/:id` | 200 | 1591 | 1 object |
| `GET …/messages?limit=50` | 200 | 6400 | 10 |
| `GET …/media?limit=30` | 200 | 36 | 0 |
| `GET …/pinned-messages` | 200 | 26 | 0 |
| `GET /chat/communities` | 200 | 26 | 0 |
| `GET /users/search?q=a` | 200 | 2231 | — |
| `GET /users/friends` | 200 | 582 | 2 |
| `GET /users/blocked` | 200 | 26 | 0 |
| `GET /users/friend-requests/pending` | 200 | 54 | 0 |
| `GET /stories/feed` | 200 | 3248 | 1 group |
| `GET /stories/discover` | 200 | 26 | 0 |
| `GET /stories/:id/views` | **403** | 66 | — not the story's author |
| `GET /apk/info?versionCode=1` | 200 | 329 | 1 object, 11 fields |

Empty collections cost **26 bytes** — the envelope alone.

### Per-row weight

`GET /chat/conversations` averaged **~1.2 KB per conversation**, carrying
`_id`, `name`, `imageUrl`, `chatType`, `lastMessage`, `unreadCount`,
`permissions`, `activeCall`, `isArchived`, `isMuted`, `isPinned`, `spaceId`,
`lastActivityAt`, `createdAt`, `deletedAt`.

A message averaged **~640 bytes**, inflated by encrypted `content` plus
`reactions`, `mentions`, `deletedForMe`, `media` and `replyTo` on every row
whether populated or not.

## Where the bytes actually go

1. **`GET /conversations`** — ~1.2 KB per row, no `limit` parameter, fired on
   every app open. Fine at 3 conversations, linear from there; the only large
   route with no bound.
2. **`GET …/messages`** — ~640 B per message, up to 50 per page. Measured 6.4 KB
   for 10. The `after` anchor should make warm reopens near-free **once the
   backend honours it** — today it does not.
3. **`POST /users/match-contacts`** — outbound, proportional to the address book.
4. **`GET …/shared-media`** — 30 per page, only when the gallery opens.

Everything else is a single object or an ack.
