# Chat API

Base path: `/api/v1/chat`

> Shared conventions — auth header, error envelope, status codes, rate limits: **[README.md](README.md)**
> **All endpoints in this module require 🔒 `Authorization: Bearer <jwt>`.**
> Real-time messaging events live in **[realtime.md](realtime.md#wschat)**.

---

## Routes at a glance

### Conversations
| Method | Path | Rate limit |
|---|---|---|
| `GET` | [`/conversations`](#get-chatconversations) | — |
| `POST` | [`/conversations`](#post-chatconversations) | 60/min |
| `GET` | [`/conversations/:id`](#get-chatconversationsid) | — |
| `PATCH` | [`/conversations/:id`](#patch-chatconversationsid) | — |
| `DELETE` | [`/conversations/:id`](#delete-chatconversationsid) | 60/min |
| `DELETE` | [`/conversations/:id/leave`](#delete-chatconversationsidleave) | — |
| `PATCH` | [`/conversations/:id/preferences`](#patch-chatconversationsidpreferences) | — |
| `PATCH` | [`/conversations/:id/permissions`](#patch-chatconversationsidpermissions) | — |

### Membership
| Method | Path |
|---|---|
| `POST` | [`/conversations/:id/members`](#post-chatconversationsidmembers) |
| `DELETE` | [`/conversations/:id/members/:userId`](#delete-chatconversationsidmembersuserid) |

### Messages
| Method | Path | Rate limit |
|---|---|---|
| `GET` | [`/conversations/:id/messages`](#get-chatconversationsidmessages) | — |
| `POST` | [`/conversations/:id/messages`](#post-chatconversationsidmessages) | 120/min |
| `POST` | [`/messages/:id/deliver`](#post-chatmessagesiddeliver) | — |
| `PATCH` | [`/conversations/:id/read`](#patch-chatconversationsidread) | — |
| `POST` | [`/messages/:id/react`](#post-chatmessagesidreact) | — |
| `POST` | [`/messages/:id/star`](#post-chatmessagesidstar) | — |
| `POST` | [`/messages/:id/pin`](#post-chatmessagesidpin) | — |
| `GET` | [`/conversations/:id/pinned-messages`](#get-chatconversationsidpinned-messages) | — |
| `DELETE` | [`/messages/:id`](#delete-chatmessagesid) | — |

### Media
| Method | Path | Rate limit |
|---|---|---|
| `POST` | [`/media/upload`](#post-chatmediaupload) | 30/min |
| `GET` | [`/conversations/:id/media`](#get-chatconversationsidmedia) | — |

### Communities, events & meetings
| Method | Path | Rate limit |
|---|---|---|
| `GET` | [`/communities`](#get-chatcommunitiescategorytech) | — |
| `POST` | [`/communities`](#post-chatcommunities) | 60/min |
| `POST` | [`/communities/:id/join`](#post-chatcommunitiesidjoin) | — |
| `DELETE` | [`/communities/:id/leave`](#delete-chatcommunitiesidleave) | — |
| `GET` | [`/communities/:id/members`](#get-chatcommunitiesidmembers) | — |
| `GET` | [`/communities/:id/preview`](#get-chatcommunitiesidpreview) | — |
| `POST` | [`/communities/:spaceId/events`](#post-chatcommunitiesspaceidevents) | 60/min |
| `GET` | [`/communities/:spaceId/events`](#get-chatcommunitiesspaceidevents) | — |
| `POST` | [`/meetings`](#post-chatmeetings) | 60/min — ⚠️ incomplete, see below |

---

## Conversation kinds

| `chatType` | What it is | Listed by |
|---|---|---|
| `direct` | 1:1 DM | `GET /conversations` |
| `group` | Private group (backed by a Space) | `GET /conversations` |
| `community` | Public channel (backed by a Space) | `GET /communities` — **not** `/conversations` |

---

## `GET /chat/conversations`

Your conversation list — direct chats and groups. Communities are **not** included.

### Query

| Param | Type | Default | Notes |
|---|---|---|---|
| `includeArchived` | `"true"` \| `"false"` | `true` | |
| `archivedOnly` | `"true"` \| `"false"` | `false` | Overrides `includeArchived` |

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66d4...",
      "chatType": "direct",
      "spaceId": null,
      "activeCall": null,
      "lastMessageAt": "2026-08-14T09:12:33.000Z",
      "createdAt": "2026-08-01T10:00:00.000Z",
      "permissions": { "sendMessages": "everyone", "editInfo": "admins", "addMembers": "admins" },
      "isPinned": false,
      "isMuted": false,
      "isArchived": false,
      "lastActivityAt": "2026-08-14T09:12:33.000Z",
      "name": "riya kapoor",
      "imageUrl": "https://gcdn.ahamcloudservices.com/talkmostest/media/...",
      "unreadCount": 3,
      "members": [
        { "_id": "66b1...", "name": "riya kapoor", "imageUrl": "https://..." }
      ],
      "lastMessage": {
        "_id": "66f0...", "chatId": "66d4...", "senderId": "66b1...", "senderName": "riya kapoor",
        "messageType": "text", "content": "on my way",
        "media": null,
        "mentions": [], "forwarded": false, "edited": false,
        "status": "delivered", "isPinned": false,
        "deletedForEveryone": false, "deletedForMe": [],
        "createdAt": "...", "updatedAt": "..."
      }
    }
  ]
}
```

**Sorting:** pinned first, then most recent activity.

**Notes**

* `lastMessage` is **absent** (not `null`) when the chat has no messages — check with `in`/`?.`, not `=== null`.
* `activeCall` holds a call id when a call is in progress in that chat → show a "join call" banner.
* ⚠️ **This endpoint returns `name`/`imageUrl`; [`GET /conversations/:id`](#get-chatconversationsid) returns `title`/`image` for the same entity.** Normalise in your model layer.
* A chat "cleared" via `preferences.hidden` stays out of this list until a **newer** message arrives (WhatsApp-style clear-chat).

---

## `GET /chat/conversations/:id`

Single conversation detail.

### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "66d4...",
    "chatType": "group",
    "spaceId": { "_id": "66d5...", "name": "Design Team", "imageUrl": "https://..." },
    "activeCall": null,
    "lastMessageAt": "...",
    "createdAt": "...",
    "title": "Design Team",
    "image": "https://...",
    "description": "Everything design",
    "role": "admin",
    "permissions": { "sendMessages": "everyone", "editInfo": "admins", "addMembers": "admins" },
    "canSendMessages": true,
    "isPinned": false,
    "isMuted": false,
    "isArchived": false,
    "unreadCount": 0,
    "participants": [
      {
        "userId": { "_id": "66b1...", "name": "riya kapoor", "username": "riya", "avatarUrl": "https://...", "status": "online", "lastSeenAt": "..." },
        "role": "member"
      }
    ],
    "lastMessage": { "_id", "senderId": { "_id", "name", "avatarUrl" }, "content", "type", "status", "createdAt" }
  }
}
```

**Notes**

* `role` — your role in this chat: `owner` / `admin` / `moderator` / `member`. Direct chats have no membership row, so both participants come back as `"member"` — don't treat `role` as a way to tell a direct chat from a group; use `chatType`.
* `canSendMessages` — your personal send flag. Also check `permissions.sendMessages === "admins"` against your `role` before enabling the composer.
* **`unreadCount` is always `0` here** — take the real count from `GET /conversations`.
* `lastMessage.type` here vs `lastMessage.messageType` in the list — another shape difference to normalise.

### Errors

| Code | Message |
|---|---|
| `400` | `ChatId is required` |
| `403` | `Not a member of this chat` |
| `404` | `Chat not found` |

---

## `POST /chat/conversations`

*Rate: 60/min.* Create a direct chat, group, or community.

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | `direct` \| `group` \| `community` | ✅ | |
| `participantIds` | string[] | ✅ | Other members (you're added automatically). For `direct`, exactly **one** id. |
| `name` | string | group/community | Required for non-direct |
| `imageUrl` | string | ❌ | |
| `description` | string | ❌ | |
| `category` | string | ❌ | Default `"Tech"` |

```json
{ "type": "group", "name": "Design Team", "participantIds": ["66b1...", "66b2..."], "imageUrl": "https://..." }
```

### Response `201` (new) / `200` (existing direct chat reused)

```json
{ "success": true, "data": { "_id": "66d4...", "chatType": "direct", "sender": "...", "receiver": "...", "lastMessageAt": "...", "permissions": {} }, "isNew": true }
```

**Notes**

* Requesting a `direct` chat that already exists returns the existing one with `isNew: false` — **safe to call unconditionally** before opening a DM.
* A previously deleted direct chat is automatically restored.
* Creating a direct chat with a non-friend only works if their account is **public** (`isPublic: true`).
* The creator becomes `owner` of a group/community.

### Errors

| Code | Message |
|---|---|
| `400` | `Invalid chat type` · `Direct chats must have exactly two members` · `Group name is required` · `A group needs at least one other member besides you` |
| `403` | `You can only message friends or public accounts` |

---

## `PATCH /chat/conversations/:id`

Rename / re-image a group or community. Governed by `permissions.editInfo`.

### Request

| Field | Type | Aliases |
|---|---|---|
| `name` | string | |
| `imageUrl` | string | `image` |
| `description` | string | `bio` |

### Response `200`

```json
{ "success": true, "data": { "chat": { "...": "..." }, "space": { "_id", "name", "imageUrl", "description", "category" } } }
```

### Errors

| Code | Message |
|---|---|
| `403` | `You do not have permission to perform this action` |
| `500` | `Chat not found` · `Direct chats cannot be renamed` · `This chat has no associated space to rename` |

---

## `DELETE /chat/conversations/:id`

*Rate: 60/min.* **Owner only.** Soft-deletes the group and removes every member. All members receive a `conversation_deleted` socket event.

### Response `200`

```json
{ "success": true, "message": "Group deleted successfully" }
```

### Errors

| Code | Message |
|---|---|
| `400` | `Direct chats cannot be deleted` |
| `403` | `Only the group owner can delete it` |
| `404` | `Chat not found` |

---

## `DELETE /chat/conversations/:id/leave`

Leave a group or community. No body.

### Response `200`

```json
{ "success": true, "message": "Left chat successfully" }
```

### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |
| `500` | `Member not found in this chat` |

> Community **owners** cannot leave — see [`DELETE /communities/:id/leave`](#delete-chatcommunitiesidleave).

---

## `PATCH /chat/conversations/:id/preferences`

Per-user chat settings. Send only what changes.

### Request

| Field | Type | Effect |
|---|---|---|
| `isPinned` | bool | Pin to top of the list |
| `isMuted` | bool | Suppress notifications |
| `isArchived` | bool | Move to the archive |
| `hidden` | bool | **"Clear chat"** — hides every existing message *for you only* and drops the chat from the list until a new message arrives |

### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "...", "userId": "...", "chatId": "...",
    "isPinned": true, "isMuted": false, "isArchived": false,
    "hiddenAt": null, "lastReadMessage": "...", "lastReadAt": "...", "lastDeliveredMessage": "..."
  }
}
```

> `hidden: true` is destructive to your local view — confirm with the user first. It cannot be undone (the messages stay hidden for you permanently).

---

## `PATCH /chat/conversations/:id/permissions`

Group-level permissions. **Admin/owner only.**

### Request

Any subset — each value is `"everyone"` or `"admins"`:

```json
{ "sendMessages": "everyone", "editInfo": "admins", "addMembers": "admins" }
```

Also accepted wrapped: `{ "permissions": { ... } }`.

### Response `200`

```json
{ "success": true, "data": { "sendMessages": "everyone", "editInfo": "admins", "addMembers": "admins" } }
```

### Errors

| Code | Message |
|---|---|
| `400` | `Invalid value for sendMessages` (or `editInfo` / `addMembers`) · `Direct chats have no permissions` |
| `403` | `Not a member of this chat` · `You do not have permission to perform this action` |
| `404` | `Chat not found` |

---

## `POST /chat/conversations/:id/members`

Add members to a group/community. Governed by `permissions.addMembers`.

### Request

```json
{ "userIds": ["66b1...", "66b2..."] }
```

### Response `201`

```json
{ "success": true, "data": [ { "_id", "chatId", "userId", "role": "member", "joinedAt", "isRemoved": false } ] }
```

> Re-adding a previously removed member **reactivates** them. Users already in the chat are skipped silently, so `data` may be shorter than `userIds`.

### Errors

| Code | Message |
|---|---|
| `400` | `userIds must be a non-empty array` |
| `403` | `You do not have permission to perform this action` |
| `500` | `Chat not found` · `Cannot add members to a direct chat` |

---

## `DELETE /chat/conversations/:id/members/:userId`

Remove a member. Admin/owner only — or yourself (equivalent to leaving).

### Response `200`

```json
{ "success": true, "message": "Member removed successfully" }
```

### Errors

| Code | Message |
|---|---|
| `403` | `You do not have permission to perform this action` · `The chat owner cannot be removed` |
| `500` | `Member not found in this chat` |

---

## `GET /chat/conversations/:id/messages`

### Query

| Param | Type | Default | Notes |
|---|---|---|---|
| `limit` | int | 50 | Max 100 |
| `before` | **ISO timestamp** | — | Page backwards: pass the `createdAt` of the oldest message you hold |
| `after` | **message id** | — | Page forwards: pass the `_id` of the newest message you hold |

> ⚠️ **Asymmetric on purpose:** `before` takes a **timestamp**, `after` takes a **message id**. If both are sent, `before` wins.

### Response `200` — always **oldest-first**

```json
{
  "success": true,
  "data": [
    {
      "_id": "66f0...",
      "chatId": "66d4...",
      "senderId": { "_id": "66b1...", "name": "riya kapoor", "avatarUrl": "https://..." },
      "messageType": "text",
      "content": "hey",
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
      "createdAt": "2026-08-14T09:12:33.000Z",
      "updatedAt": "2026-08-14T09:12:33.000Z",
      "reactions": [
        { "_id": "...", "messageId": "66f0...", "userId": { "_id": "66b0...", "name": "amit sharma" }, "emoji": "👍", "createdAt": "..." }
      ],
      "isStarred": false
    }
  ]
}
```

**Notes**

* Messages you deleted for yourself are filtered out automatically.
* `media` is `null` on messages sent without any — every text message. Read it as `media?.url`, not `media.url`.
* `deletedForEveryone: true` messages **are** returned, with blanked `content`/`media` — render a "This message was deleted" tombstone.
* `replyTo`, when present, is a nested message object with its own populated `senderId`.

### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |
| `404` | `Chat not found` |

---

## `POST /chat/conversations/:id/messages`

*Rate: 120/min.* HTTP alternative to the `send_chat_message` socket event — same persistence and the same fan-out (socket delivery to online members + FCM push to offline ones).

> **Prefer the socket event when the socket is connected.** This route can't carry `senderName` or `clientMessageId`, so the recipient's push notification title falls back to a blank value and you get no echo id for reconciling optimistic sends. Use REST as the offline/retry path.

### Request

| Field | Type | Notes |
|---|---|---|
| `messageType` | enum | Default `"text"` — see [enums.md](enums.md#message-types) |
| `content` | string | Text body / caption |
| `media` | object | `{ url, thumbnail, fileName, mimeType, size, duration }`. Omit it for text messages — the stored message then carries `media: null`, which is what reads back. |
| `mediaUrl` | string | Shorthand for `media.url` |
| `mediaMeta` | object | Alternative carrier for `thumbnail`/`size`/`duration`/`mimeType`/`fileName` |
| `replyToId` | string | `_id` of the message being replied to |

```json
{
  "messageType": "image",
  "content": "look at this",
  "mediaUrl": "https://gcdn.ahamcloudservices.com/talkmostest/media/2026/08/ab12_photo.jpg",
  "mediaMeta": { "mimeType": "image/jpeg", "size": 184203, "fileName": "photo.jpg", "thumbnail": "https://..." }
}
```

### Response `201`

```json
{ "success": true, "data": { "...message, with senderId and replyTo populated" } }
```

### Errors

| Code | Message | Meaning |
|---|---|---|
| `403` | `You cannot send messages to this user` | Blocked either way |
| `403` | `You can only message friends or public accounts` | Stranger with a private account |
| `403` | `You do not have permission to send messages` | Your member flag is off |
| `403` | `Only admins can send messages in this group` | `permissions.sendMessages === "admins"` |
| `404` | `Chat not found` | |

---

## `POST /chat/messages/:id/deliver`

Mark a received message as delivered. No body.

### Response `200`

```json
{ "success": true, "data": { "...message" } }
```

> **`data` is `null`** when nothing changed — already delivered/read, sent by you, or gone. That is **not** an error; don't retry.

The sender receives a `message_delivered` socket event.

---

## `PATCH /chat/conversations/:id/read`

Mark the thread read.

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `senderId` | string | ❌ | Restrict to one sender's messages. Omit to mark everything from everyone else. |

### Response `200`

```json
{ "success": true, "data": { "success": true, "sentReadReceipt": true } }
```

> **`sentReadReceipt: false`** means the reader has read receipts disabled — messages were **not** flipped to `read` and no receipt was broadcast. In that case don't render blue ticks for the other side. Your own unread cursor still advances either way.

Broadcasts `messages_read` to the chat room.

---

## `POST /chat/messages/:id/react`

One reaction per user per message — sending a new emoji replaces the previous one.

### Request

```json
{ "emoji": "👍" }
```

Send `null`, `""`, or omit `emoji` to **remove** your reaction.

### Response `200`

```json
{
  "success": true,
  "data": {
    "status": "reacted",
    "reaction": { "_id": "...", "messageId": "...", "userId": "...", "emoji": "👍", "createdAt": "..." },
    "chatId": "66d4..."
  }
}
```

`status` ∈ `reacted` | `removed` (on removal there's no `reaction` key).

Broadcasts `message_reaction` to the chat room with `emoji: null` when removed.

### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |
| `500` | `Message not found` |

---

## `POST /chat/messages/:id/star`

Private bookmark — visible only to you.

### Request

```json
{ "star": true }
```

### Response `200`

```json
{ "success": true, "data": { "status": "starred", "star": { "_id", "userId", "messageId" } } }
```

`status` ∈ `starred` | `unstarred`. Idempotent.

> Starred state comes back on each message as `isStarred` in `GET /conversations/:id/messages`.

---

## `POST /chat/messages/:id/pin`

Pin/unpin a message for the whole chat.

### Request

```json
{ "isPinned": true }
```

### Response `200`

```json
{ "success": true, "data": { "...message with senderId populated, isPinned: true, pinnedAt: '...'" } }
```

Broadcasts `message_pinned` to every member.

### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |
| `500` | `Message not found` |

---

## `GET /chat/conversations/:id/pinned-messages`

### Response `200`

```json
{ "success": true, "data": [ { "...message with senderId populated" } ] }
```

Most recently pinned first. Deleted-for-everyone messages are excluded.

---

## `DELETE /chat/messages/:id`

### Request

| Field | Type | Default | Notes |
|---|---|---|---|
| `forEveryone` | bool | `false` | `false` = delete for me only |

### Response `200`

```json
{ "success": true, "message": "Message deleted successfully" }
```

### Errors

| Code | Message |
|---|---|
| `403` | `You can only delete your own messages for everyone` · `Not a member of this chat` |
| `500` | `Message not found` |

> Delete-for-everyone blanks `content` and `media` and sets `deletedForEveryone: true` — the row survives, so render a tombstone rather than removing the bubble.
> There is **no time limit** on delete-for-everyone.

---

## Media upload

### `POST /chat/media/upload`

*Rate: 30/min.* Returns a **presigned upload URL**. The file never passes through this API — you `PUT` the bytes straight to the media host.

#### Request

```json
{ "fileName": "photo.jpg", "mimeType": "image/jpeg" }
```

#### Response `201`

```json
{
  "success": true,
  "uploadUrl": "https://gcdn.ahamcloudservices.com/talkmostest/media/2026/08/ab12cd34ef567890_photo.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=...&X-Amz-Date=...&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=...",
  "method": "PUT",
  "fields": {},
  "headers": { "Content-Type": "image/jpeg" },
  "mediaUrl": "https://gcdn.ahamcloudservices.com/talkmostest/media/2026/08/ab12cd34ef567890_photo.jpg",
  "expiresIn": 900,
  "fileName": "photo.jpg",
  "mimeType": "image/jpeg"
}
```

#### Client flow

1. `POST /chat/media/upload` with the filename + MIME type.
2. Raw `PUT` the bytes to `uploadUrl` with the returned `headers`. No form fields, no auth header — the URL carries its own signature. Send the body as-is; do **not** wrap it in `multipart/form-data`.
3. Send the message with **`mediaUrl`** — the permanent, unsigned read URL. Never store `uploadUrl`.

> **`expiresIn` is a deadline.** The signature is valid for that many seconds (900 by default). Ask for the URL when the user confirms the send, not when they open the picker, and request a fresh one if an upload is retried after it lapses. An expired URL returns `403` from the media host with an `AccessDenied` XML body.

> **`fields` is always `{}`.** It survives from the previous storage provider so older clients branching on `method` keep working.

`mediaUrl` stays readable forever and needs no credentials, which is why it is safe to store on the message. Objects are readable by anyone holding the URL; the bucket cannot be listed.

#### Errors

| Code | Message |
|---|---|
| `400` | `fileName is required` / `mimeType must be a valid MIME type` / `fileName must not contain path separators` |
| `503` | `Media storage is not configured on this server` |

---

### `GET /chat/conversations/:id/media`

Shared photos and videos in a conversation.

#### Query

| Param | Type | Default | Notes |
|---|---|---|---|
| `limit` | int | 30 | Max 100 |
| `before` | ISO timestamp | — | Page backwards |

#### Response `200`

```json
{
  "success": true,
  "data": [
    { "_id": "66f0...", "messageType": "image", "media": { "url": "https://...", "thumbnail": "https://...", "fileName": "photo.jpg", "mimeType": "image/jpeg", "size": 184203, "duration": 0 }, "createdAt": "..." }
  ],
  "total": 128
}
```

Newest first. Only `image` and `video` messages.

> `total` is cached for 60 s — treat it as approximate for the "128 items" header.

#### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |
| `404` | `Chat not found` |

---

## Communities

> ⚠️ **The `:id` param means two different things:**
> * `/communities/:id/join`, `/leave`, `/members`, `/preview` → the community's **chat id** (the `_id` from `GET /communities`)
> * `/communities/:id/events` (GET & POST) → the community's **space id**
>
> `GET /communities` currently strips `spaceId` from its output, so keep the `space._id` you got from `POST /communities` if you need the events endpoints.

### `GET /chat/communities?category=Tech`

Public community directory.

#### Query

| Param | Type | Notes |
|---|---|---|
| `category` | string | Optional filter |

#### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66d6...",
      "chatType": "community",
      "name": "Flutter India",
      "description": "Everything Flutter",
      "imageUrl": "https://...",
      "category": "Tech",
      "isVerified": false,
      "owner": "66b0...",
      "createdBy": "66b0...",
      "memberCount": 42,
      "isMember": true,
      "permissions": { "sendMessages": "everyone", "editInfo": "admins", "addMembers": "admins" },
      "lastMessageAt": "...",
      "createdAt": "...",
      "lastActivityAt": "...",
      "lastMessage": { "_id", "senderId", "senderName", "messageType", "content", "media", "status", "createdAt" }
    }
  ]
}
```

Sorted by most recent activity. `_id` is the **chat id** — use it for `/join`, `/members`, `/preview`, and all message endpoints.

> `lastMessage` is absent when the community has no messages.
> Use `isMember` to switch the CTA between "Join" and "Open".

---

### `POST /chat/communities`

*Rate: 60/min.*

#### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | ✅ | |
| `description` | string | ❌ | |
| `imageUrl` | string | ❌ | Alias `iconUrl` |
| `category` | string | ❌ | Default `"Tech"` |

#### Response `201`

```json
{
  "success": true,
  "data": {
    "space": { "_id": "66d7...", "name": "Flutter India", "description": "...", "imageUrl": "...", "category": "Tech", "owner": "...", "createdBy": "..." },
    "generalChat": { "_id": "66d6...", "chatType": "community", "spaceId": "66d7...", "permissions": { } }
  }
}
```

> **Keep both ids.** `generalChat._id` is the chat id for messaging/join/members; `space._id` is what the events endpoints want.
> The creator becomes `owner`.

#### Errors

| Code | Message |
|---|---|
| `500` | `Community name is required` |

---

### `POST /chat/communities/:id/join`

`:id` = **chat id**. No body. Idempotent — rejoining after leaving works.

#### Response `200`

```json
{ "success": true, "data": { "_id", "chatId", "userId", "role": "member", "joinedAt", "isRemoved": false } }
```

#### Errors

| Code | Message |
|---|---|
| `500` | `Community chat not found` · `Space not found` |

---

### `DELETE /chat/communities/:id/leave`

`:id` = **chat id**.

#### Response `200`

```json
{ "success": true, "message": "Left space successfully" }
```

#### Errors

| Code | Message |
|---|---|
| `500` | `Community chat not found` · `Not a member of this community` · `The owner cannot leave the community` |

---

### `GET /chat/communities/:id/members`

`:id` = **chat id**.

#### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "...", "chatId": "66d6...",
      "userId": { "_id": "66b0...", "name": "amit sharma", "username": "amit", "avatarUrl": "https://...", "email": "...", "status": "online" },
      "role": "owner", "joinedAt": "...", "isRemoved": false
    }
  ]
}
```

---

### `GET /chat/communities/:id/preview`

`:id` = **chat id**. Invite-link landing page — **deliberately works for non-members** so someone who tapped a link can see what they'd be joining.

#### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "66d6...",
    "name": "Flutter India",
    "description": "Everything Flutter",
    "imageUrl": "https://...",
    "category": "Tech",
    "isVerified": false,
    "memberCount": 42,
    "isMember": false
  }
}
```

#### Errors

| Code | Message |
|---|---|
| `404` | `Community not found` |

---

## Events

> Both event routes take the **space id**, not the chat id.

### `POST /chat/communities/:spaceId/events`

*Rate: 60/min.* Must be a member of the community.

#### Request

| Field | Type | Required | Default |
|---|---|---|---|
| `title` | string | ✅ | |
| `description` | string | ❌ | `""` |
| `startTime` | ISO date | ❌ | now |
| `endTime` | ISO date | ❌ | start + 1 h |
| `location` | string | ❌ | `"Online"` |

#### Response `201`

```json
{
  "success": true,
  "data": {
    "_id": "66e8...", "communityId": "66d7...",
    "title": "Flutter meetup", "description": "...",
    "startTime": "...", "endTime": "...", "location": "Online",
    "meetingId": null, "createdBy": "66b0...", "createdAt": "..."
  }
}
```

#### Errors

| Code | Message |
|---|---|
| `403` | `Not a member of this chat` |
| `500` | `Space not found` · `General chat for space not found` |

---

### `GET /chat/communities/:spaceId/events`

#### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66e8...", "title": "Flutter meetup", "description": "...",
      "startTime": "...", "endTime": "...", "location": "Online",
      "createdBy": { "_id": "66b0...", "name": "amit sharma", "avatarUrl": "https://..." }
    }
  ]
}
```

Sorted by `startTime` **ascending**. Past events are included — filter client-side if you only want upcoming ones.

---

## `POST /chat/meetings`

> ⚠️ **Incomplete — do not integrate against this yet.** Creating a meeting is the only thing the feature does. There is no lookup, join or end endpoint, and the `joinLink` it returns (`https://talkmos.com/meet/<code>`) is **not served by anything** — following it 404s. A client that surfaces this hands the user a dead link. It is documented here only so nobody rediscovers it by reading the route table and assumes it works.

*Rate: 60/min.* Creates a shareable meeting code + join link.

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | `instant` \| `scheduled` | ❌ | Default `instant` |
| `scheduledAt` | ISO date | for `scheduled` | |

### Response `201`

```json
{
  "success": true,
  "data": {
    "_id": "66e9...",
    "meetingCode": "a1b2-c3d4-e5f6",
    "hostId": "66b0...",
    "type": "instant",
    "scheduledAt": null,
    "status": "ongoing",
    "joinLink": "https://talkmos.com/meet/a1b2-c3d4-e5f6",
    "createdAt": "..."
  }
}
```

`status` is `ongoing` for `instant`, `scheduled` for `scheduled`.
