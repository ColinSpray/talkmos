# Admin API

Base path: `/api/v1/admin`

> Shared conventions — auth header, error envelope, status codes: **[README.md](README.md)**
> **Every endpoint requires 🔒 `Authorization: Bearer <jwt>` *and* `role: "admin"`.**

Non-admins get:

```json
{ "success": false, "message": "Access denied: Administrative privileges required" }
```
with status `403`.

> **Every request to this module is written to the audit log** — method, path, body, params, query, status code, admin identity and IP. Assume anything you do here is permanently attributable.

---

## Routes at a glance

### Dashboard
| Method | Path |
|---|---|
| `GET` | [`/stats`](#get-adminstats) |
| `GET` | [`/stats/timeseries`](#get-adminstatstimeseries) |
| `GET` | [`/search`](#get-adminsearchq) |

### Users
| Method | Path |
|---|---|
| `GET` | [`/users`](#get-adminusers) |
| `GET` | [`/users/:id`](#get-adminusersid) |
| `PATCH` | [`/users/:id`](#patch-adminusersid) |
| `DELETE` | [`/users/:id`](#delete-adminusersid) |
| `DELETE` | [`/users/:id/devices/:deviceId`](#delete-adminusersiddevicesdeviceid) |

### Moderation
| Method | Path |
|---|---|
| `GET` / `DELETE` | [`/chats`](#get-adminchats) · [`/chats/:id`](#delete-adminchatsid) |
| `GET` / `DELETE` | [`/messages`](#get-adminmessages) · [`/messages/:id`](#delete-adminmessagesid) |
| `GET` / `DELETE` | [`/stories`](#get-adminstories) · [`/stories/:id`](#delete-adminstoriesid) |
| `GET` | [`/calls`](#get-admincalls) · [`/calls/:id`](#get-admincallsid) |

### Operations
| Method | Path |
|---|---|
| `GET` | [`/settings`](#get-adminsettings) |
| `PATCH` | [`/settings`](#patch-adminsettings) |
| `GET` | [`/audit-logs`](#get-adminaudit-logs) |
| `POST` | [`/notifications/broadcast`](#post-adminnotificationsbroadcast) |

---

## Pagination

Every list endpoint shares this shape:

```json
{
  "success": true,
  "data": [ "…" ],
  "pagination": { "total": 340, "page": 1, "pages": 17 }
}
```

Query params `page` (default 1) and `limit` (default varies per endpoint). All lists are sorted `createdAt` descending.

---

## `GET /admin/stats`

Headline counters for the dashboard.

### Response `200`

```json
{
  "success": true,
  "data": {
    "users": { "total": 12400, "premium": 340, "verified": 8100, "admin": 3 },
    "stats": { "messages": 1840221, "chats": 30112, "calls": 44201 }
  }
}
```

> These are full-collection counts computed on every request — don't poll this endpoint on a short interval.

---

## `GET /admin/stats/timeseries`

Daily trend data for charts.

### Query

| Param | Type | Default | Max |
|---|---|---|---|
| `days` | int | 30 | 90 |

### Response `200`

```json
{
  "success": true,
  "data": [
    { "date": "2026-07-16", "signups": 12, "messages": 4021, "calls": 88 },
    { "date": "2026-07-17", "signups": 0,  "messages": 3980, "calls": 91 }
  ]
}
```

**Zero-filled** — there's exactly one point per day in range, oldest first, so you can plot it directly without gap handling.

---

## `GET /admin/search?q=`

Global lookup. Two modes, combined in one response:

* If `q` is a **24-char ObjectId**, it's looked up across users, chats, messages, stories and calls.
* Always, `q` is also run as a case-insensitive text search over users (name / email / phone / username), max 10 results.

### Response `200`

```json
{
  "success": true,
  "data": [
    { "type": "user",    "item": { "...user, password excluded" } },
    { "type": "message", "item": { "...message, senderId populated" } }
  ]
}
```

`type` ∈ `user` · `chat` · `message` · `story` · `call`. Duplicates are removed. An empty `q` returns `data: []`.

---

## `GET /admin/users`

### Query

| Param | Type | Default | Notes |
|---|---|---|---|
| `page` | int | 1 | |
| `limit` | int | 20 | |
| `search` | string | — | Regex-escaped; matches name / fullName / email / phone / username |
| `role` | `user` \| `admin` | — | |
| `isPremium` | `"true"` \| `"false"` | — | |
| `isVerified` | `"true"` \| `"false"` | — | |

### Response `200`

```json
{
  "success": true,
  "data": [ { "...user, password excluded" } ],
  "pagination": { "total": 12400, "page": 1, "pages": 620 }
}
```

---

## `GET /admin/users/:id`

Full 360° view of one user.

### Response `200`

```json
{
  "success": true,
  "data": {
    "user": { "...full user, password excluded" },
    "devices": [ { "_id", "deviceId", "deviceName", "platform", "isActive", "ip", "userAgent", "loginAt", "lastActiveAt", "loggedOutAt" } ],
    "friends": [ { "_id", "name", "username", "email", "phone", "avatarUrl", "status" } ],
    "chats": [
      { "_id": "...", "chatType": "direct", "other": { "_id", "name" }, "updatedAt": "..." },
      { "_id": "...", "chatType": "group",  "role": "member",           "updatedAt": "..." }
    ],
    "calls": [ { "_id", "callType", "status", "startedAt", "endedAt", "duration", "initiatedBy", "myStatus" } ]
  }
}
```

**Caps:** `chats` is capped at 20 direct + 20 group; `calls` at the 20 most recent. `devices` and `friends` are complete.
`devices` excludes `fcmToken` by design.

### Errors

| Code | Message |
|---|---|
| `404` | `User not found` |

---

## `PATCH /admin/users/:id`

### Request

| Field | Type | Notes |
|---|---|---|
| `role` | `user` \| `admin` | **Grants full admin access** — no second confirmation server-side |
| `isPremium` | bool | |
| `isVerified` | bool | |
| `premiumExpiry` | ISO date \| `null` | |

### Response `200`

```json
{ "success": true, "data": { "...updated user" } }
```

### Errors

| Code | Message |
|---|---|
| `404` | `User not found` |

> Promoting to `admin` takes effect within ~5 minutes (user cache TTL) or immediately on their next fresh login.

---

## `DELETE /admin/users/:id`

Hard-deletes the user document.

### Response `200`

```json
{ "success": true, "message": "User deleted successfully" }
```

### Errors

| Code | Message |
|---|---|
| `400` | `You cannot delete your own administrative account` |
| `404` | `User not found` |

> ⚠️ This deletes **only the User row**. Their messages, chats, stories, call records and device sessions are left behind and will render with a dangling reference. Clean up related records manually if that matters.

---

## `DELETE /admin/users/:id/devices/:deviceId`

Force-logout one of a user's devices. Their live sockets are disconnected immediately.

### Response `200`

```json
{ "success": true, "message": "Device logged out" }
```

### Errors

| Code | Message |
|---|---|
| `404` | `Device session not found` |

---

## `GET /admin/chats`

### Query

`page` (1) · `limit` (20) · `chatType` (`direct` \| `group` \| `community`)

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66d4...", "chatType": "direct",
      "sender": { "_id", "name", "email", "phone" },
      "receiver": { "_id", "name", "email", "phone" },
      "spaceId": { "_id", "name", "imageUrl" },
      "lastMessageAt": "...", "deletedAt": null, "permissions": { }, "createdAt": "..."
    }
  ],
  "pagination": { "total": 30112, "page": 1, "pages": 1506 }
}
```

---

## `DELETE /admin/chats/:id`

**Hard delete** — removes the chat document **and every message in it**. Not a soft delete, not reversible.

### Response `200`

```json
{ "success": true, "message": "Chat deleted successfully" }
```

### Errors

| Code | Message |
|---|---|
| `404` | `Chat not found` |

---

## `GET /admin/messages`

### Query

`page` (1) · `limit` (50) · `chatId` · `senderId` · `messageType`

### Response `200`

```json
{
  "success": true,
  "data": [ { "...message, senderId populated with name/email/phone" } ],
  "pagination": { "total": 1840221, "page": 1, "pages": 36805 }
}
```

> Without a `chatId` or `senderId` filter this scans the largest collection in the system. Always filter.

---

## `DELETE /admin/messages/:id`

**Hard delete** — unlike the user-facing delete, this removes the row entirely rather than tombstoning it.

### Response `200`

```json
{ "success": true, "message": "Message deleted successfully" }
```

### Errors

| Code | Message |
|---|---|
| `404` | `Message not found` |

---

## `GET /admin/stories`

### Query

`page` (1) · `limit` (20) · `userId` · `category`

### Response `200`

```json
{
  "success": true,
  "data": [ { "...story, userId populated with name/email/phone" } ],
  "pagination": { "total": 812, "page": 1, "pages": 41 }
}
```

---

## `DELETE /admin/stories/:id`

Hard delete.

### Response `200`

```json
{ "success": true, "message": "Story deleted successfully" }
```

### Errors

| Code | Message |
|---|---|
| `404` | `Story not found` |

> This removes the Story row but **not** its `StoryView` records — unlike the user-facing delete, which cleans both.

---

## `GET /admin/calls`

### Query

`page` (1) · `limit` (20) · `status` · `callType`

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66e1...", "chatId": "66d4...",
      "initiatedBy": { "_id", "name", "email", "phone" },
      "callType": "video", "isGroupCall": false, "status": "ended",
      "startedAt": "...", "endedAt": "...", "duration": 88, "createdAt": "..."
    }
  ],
  "pagination": { "total": 44201, "page": 1, "pages": 2211 }
}
```

`status` values: [calls.md → status reference](calls.md#status-reference).

---

## `GET /admin/calls/:id`

### Response `200`

```json
{
  "success": true,
  "data": {
    "...call, initiatedBy populated",
    "participants": [ { "_id", "callId", "userId": { "_id", "name", "email", "phone" }, "status", "joinedAt", "leftAt" } ]
  }
}
```

### Errors

| Code | Message |
|---|---|
| `404` | `Call not found` |

---

## `GET /admin/settings`

### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "66a0...",
    "allowNewRegistrations": true,
    "maintenanceMode": false,
    "allowedEmailDomains": [],
    "latestVersionName": "1.1.1",
    "latestVersionCode": 10,
    "minRequiredVersionCode": 1,
    "releaseNotes": "Bug fixes and performance improvements.",
    "isForceUpdate": false,
    "createdAt": "...", "updatedAt": "..."
  }
}
```

Cached server-side for 1 hour; writes invalidate the cache immediately.

---

## `PATCH /admin/settings`

Send only what changes.

### Request

| Field | Type | Effect |
|---|---|---|
| `allowNewRegistrations` | bool | `false` → `/auth/register` and first-time Google login return `403` |
| `maintenanceMode` | bool | **Stored but not currently enforced** by any route |
| `allowedEmailDomains` | string[] | **Stored but not currently enforced** |
| `latestVersionName` | string | Feeds `GET /apk/info` |
| `latestVersionCode` | int | Feeds `GET /apk/info` |
| `minRequiredVersionCode` | int | Below this, clients are force-updated |
| `releaseNotes` | string | Shown in the update dialog |
| `isForceUpdate` | bool | Forces the update dialog for **all** clients |

### Response `200`

```json
{ "success": true, "data": { "...updated settings" } }
```

> ⚠️ `maintenanceMode` and `allowedEmailDomains` are persisted but **no route reads them** — flipping them changes nothing today. Don't build an admin UI that implies they work.
> `isForceUpdate: true` blocks every client on the next app start. Verify the APK is actually uploaded first.

---

## `GET /admin/audit-logs`

### Query

`page` (1) · `limit` (50)

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66h1...",
      "adminId": { "_id", "name", "email", "phone" },
      "adminEmail": "admin@talkmos.com",
      "method": "DELETE",
      "path": "/api/v1/admin/messages/66f0...",
      "body": { }, "params": { "id": "66f0..." }, "query": { },
      "statusCode": 200,
      "ipAddress": "203.0.113.7",
      "createdAt": "..."
    }
  ],
  "pagination": { "total": 4210, "page": 1, "pages": 85 }
}
```

Newest first. Logs are written after the response completes, so a request's own log row won't be in its own response.

---

## `POST /admin/notifications/broadcast`

Sends an in-app notification **and** an FCM push to a segment of users.

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `target` | `all` \| `premium` \| `verified` \| `unverified` \| `user` | ✅ | |
| `userId` | string | for `target: "user"` | |
| `title` | string | ✅ | |
| `body` | string | ✅ | |
| `imageUrl` | string | ❌ | Passed through in the push `data` and notification `metadata` |

```json
{ "target": "premium", "title": "New feature", "body": "Nearby is live!", "imageUrl": "https://..." }
```

### Response `200`

```json
{ "success": true, "data": { "recipients": 340, "pushed": 312, "failed": 28 } }
```

| Field | Meaning |
|---|---|
| `recipients` | Users who got an in-app notification row |
| `pushed` | Device tokens that accepted the push |
| `failed` | Device tokens that rejected it (stale/uninstalled) |

`failed > 0` is normal — dead tokens accumulate. Only worry if `pushed` is near zero.

### Errors

| Code | Message |
|---|---|
| `400` | `title and body are required` · `target must be one of: all, premium, verified, unverified, user` · `userId is required for target "user"` |
| `404` | `User not found` |

> ⚠️ `target: "all"` writes one notification row **per user** and pushes to every active device. There is no dry-run, no scheduling and no undo. Test with `target: "user"` against your own account first.
