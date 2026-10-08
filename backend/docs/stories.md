# Stories API

Base path: `/api/v1/stories`

> Shared conventions — auth header, error envelope, status codes, rate limits: **[README.md](README.md)**
> **All endpoints in this module require 🔒 `Authorization: Bearer <jwt>`.**

---

## Routes at a glance

| Method | Path | Rate limit |
|---|---|---|
| `GET` | [`/feed`](#get-storiesfeed) | — |
| `GET` | [`/discover`](#get-storiesdiscovercategorytravel) | — |
| `POST` | [`/`](#post-stories) | 30/5min |
| `GET` | [`/:id`](#get-storiesid) | — |
| `POST` | [`/:id/view`](#post-storiesidview) | 300/min |
| `GET` | [`/:id/views`](#get-storiesidviews) | — |
| `DELETE` | [`/:id`](#delete-storiesid) | — |

> **Route order:** `/feed` and `/discover` are registered before `/:id`, so they're never captured by it.

---

## Lifecycle

* Stories expire **24 hours** after creation (`expiresAt` is set automatically).
* Expired stories are purged hourly by a background job, along with their view records.
* Expired stories never appear in feeds and return `404` when fetched directly.

---

## `GET /stories/feed`

Your own stories + friends' stories + all public stories, **grouped by author**.

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "user": { "_id": "66b1...", "name": "riya kapoor", "avatarUrl": "https://...", "isPublic": true },
      "stories": [
        {
          "_id": "66f1...",
          "userId": { "_id": "66b1...", "name": "riya kapoor", "avatarUrl": "https://...", "isPublic": true },
          "mediaUrl": "https://gcdn.ahamcloudservices.com/talkmostest/media/...",
          "mediaType": "image",
          "caption": "sunset",
          "visibility": "friends",
          "category": "Friends",
          "expiresAt": "2026-08-15T09:12:33.000Z",
          "createdAt": "2026-08-14T09:12:33.000Z",
          "updatedAt": "...",
          "viewed": false
        }
      ]
    }
  ]
}
```

**Notes**

* Stories within each group are **newest-first**.
* `viewed` is per-story, for the current user — use it to draw the seen/unseen ring.
* Blocked users (either direction) are excluded entirely.
* Your **own** group is included — find it by matching `user._id` against your user id.
* Public stories from strangers appear here too, not just friends'.
* An empty `data: []` is normal for a new account.

---

## `GET /stories/discover?category=Travel`

Public stories only, excluding your own. Flat array — **not** grouped.

### Query

| Param | Type | Required | Notes |
|---|---|---|---|
| `category` | string | ❌ | Omit for all categories |

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66f2...",
      "userId": { "_id": "66b3...", "name": "sonal", "avatarUrl": "https://...", "isPublic": true },
      "mediaUrl": "https://...",
      "mediaType": "video",
      "caption": "goa trip",
      "visibility": "public",
      "category": "Travel",
      "expiresAt": "...",
      "createdAt": "..."
    }
  ]
}
```

Newest-first, capped at **200** stories.

> Unlike `/feed`, discover entries carry **no `viewed` flag** — track seen state locally if you need it here.

---

## `POST /stories`

*Rate: 30 / 5 min.* Upload the media first via [`POST /chat/media/upload`](chat.md#post-chatmediaupload).

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `mediaUrl` | string | ✅ | The `mediaUrl` returned by the upload endpoint |
| `mediaType` | `image` \| `video` | ✅ | |
| `caption` | string | ❌ | Default `""` |
| `visibility` | `friends` \| `public` | ❌ | Default `friends` |
| `category` | string | ❌ | Default `"Friends"` — used by the discover feed's filter |

```json
{
  "mediaUrl": "https://gcdn.ahamcloudservices.com/talkmostest/media/2026/08/ab12_sunset.jpg",
  "mediaType": "image",
  "caption": "sunset",
  "visibility": "public",
  "category": "Travel"
}
```

### Response `201`

```json
{
  "success": true,
  "data": {
    "_id": "66f1...", "userId": "66b0...",
    "mediaUrl": "https://...", "mediaType": "image",
    "caption": "sunset", "visibility": "public", "category": "Travel",
    "expiresAt": "2026-08-15T09:12:33.000Z",
    "createdAt": "...", "updatedAt": "..."
  }
}
```

> `visibility: "friends"` → only accepted friends can view it.
> `visibility: "public"` → anyone, and it appears in `/discover`.

### Errors

| Code | Message |
|---|---|
| `400` | `mediaUrl and mediaType are required` |

---

## `GET /stories/:id`

Single story — for deep links.

### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "66f1...",
    "userId": { "_id": "66b1...", "name": "riya kapoor", "avatarUrl": "https://...", "isPublic": true },
    "mediaUrl": "https://...", "mediaType": "image", "caption": "sunset",
    "visibility": "friends", "category": "Friends",
    "expiresAt": "...", "createdAt": "..."
  }
}
```

### Errors

| Code | Message | Meaning |
|---|---|---|
| `404` | `Story not found or expired` | Deleted, expired, **or** either party has blocked the other |
| `403` | `This story is only visible to friends` | `visibility: "friends"` and you're not a friend |

> Distinguish the two in your UI: `403` can offer "Send a friend request"; `404` should just say the story is unavailable.

---

## `POST /stories/:id/view`

*Rate: 300/min.* Mark a story as viewed. No body. **Idempotent** — repeat calls just refresh `viewedAt`.

### Response `200`

```json
{
  "success": true,
  "data": { "_id": "66f5...", "storyId": "66f1...", "viewerId": "66b0...", "viewedAt": "...", "createdAt": "..." }
}
```

### Errors

| Code | Message |
|---|---|
| `404` | `Story not found or expired` |

> The limit is generous (300/min) because scrolling a feed legitimately fires one call per story. Still, fire it once per story per session, not on every frame.

---

## `GET /stories/:id/views`

Who viewed your story. **Author only.**

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66f5...", "storyId": "66f1...",
      "viewerId": { "_id": "66b1...", "name": "riya kapoor", "avatarUrl": "https://...", "status": "online" },
      "viewedAt": "2026-08-14T09:20:00.000Z", "createdAt": "..."
    }
  ]
}
```

Viewer count = `data.length`.

### Errors

| Code | Message |
|---|---|
| `403` | `Forbidden: You do not own this story` |
| `404` | `Story not found` |

---

## `DELETE /stories/:id`

Delete your own story. **Author only.** Also removes all its view records.

### Response `200`

```json
{ "success": true, "message": "Story deleted successfully" }
```

### Errors

| Code | Message |
|---|---|
| `403` | `Forbidden: You do not own this story` |
| `404` | `Story not found` |
