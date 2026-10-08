# Users API

Base path: `/api/v1/users`

> Shared conventions — auth header, error envelope, status codes, rate limits: **[README.md](README.md)**
> **All endpoints in this module require 🔒 `Authorization: Bearer <jwt>`.**

---

## Routes at a glance

| Method | Path | Rate limit |
|---|---|---|
| `GET` | [`/search`](#get-userssearchqtext) | 60/min |
| `POST` | [`/contacts/match`](#post-userscontactsmatch) | 10/5min |
| `PUT` | [`/profile`](#put-usersprofile) | — |
| `POST` | [`/friend-requests`](#post-usersfriend-requests) | 60/5min |
| `GET` | [`/friend-requests/pending`](#get-usersfriend-requestspending) | — |
| `PUT` | [`/friend-requests/:id`](#put-usersfriend-requestsid) | — |
| `GET` | [`/friends`](#get-usersfriends) | — |
| `PATCH` | [`/nearby/settings`](#patch-usersnearbysettings) | 20/5min per user |
| `POST` | [`/nearby/heartbeat`](#post-usersnearbyheartbeat) | 30/min |
| `POST` | [`/nearby/ping`](#post-usersnearbyping) | 20/5min |
| `POST` | [`/nearby/request`](#post-usersnearbyrequest) | **5/day per user** |
| `GET` | [`/blocked`](#blocking) | — |
| `POST` | [`/block/:id`](#blocking) | — |
| `POST` | [`/unblock/:id`](#blocking) | — |
| `GET` | [`/:id`](#get-usersid) | — |

> **Route order:** `GET /users/:id` is registered last, so `/search`, `/friends`, `/blocked`, `/nearby/*` and `/contacts/match` are never shadowed by it.

---

## `GET /users/search?q=<text>`

*Rate: 60/min.* Case-insensitive substring match on name, email, phone and username. Excludes yourself and admin accounts. **Max 20 results.**

### Query

| Param | Type | Required |
|---|---|---|
| `q` | string | ✅ |

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66b1...",
      "name": "riya kapoor",
      "username": "riya",
      "email": "riya@example.com",
      "phone": "+919876543211",
      "avatarUrl": "https://gcdn.ahamcloudservices.com/talkmostest/media/...",
      "status": "online",
      "isVerified": false
    }
  ]
}
```

> `avatarUrl` comes back as `""` when that user's `profilePhotoVisibility` hides it from you — render a placeholder, don't treat it as a broken image.

### Errors

| Code | Message |
|---|---|
| `400` | `Query required` |

---

## `GET /users/:id`

Public profile lookup — for resolving a deep link before opening a chat.

### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "66b1...",
    "name": "riya kapoor",
    "username": "riya",
    "avatarUrl": "https://...",
    "bio": "designer",
    "isVerified": false,
    "isPublic": true
  }
}
```

> `isPublic: false` means you can only DM/call this person if you're already friends — grey out those actions and offer "Send friend request" instead.

### Errors

| Code | Message | Meaning |
|---|---|---|
| `404` | `User not found` | Doesn't exist **or** either party has blocked the other |

> Treat `404` here as "not available", not necessarily "deleted".

---

## `POST /users/contacts/match`

*Rate: 10 / 5 min.* Phone-book sync. Matching is done on the **last 10 digits**, so country-code and formatting differences don't matter.

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `phones` | string[] | ✅ | Max **2000** per call — extras are silently ignored |

```json
{ "phones": ["+91 98765 43210", "9876543211", "(987) 654-3212"] }
```

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66b1...",
      "name": "riya kapoor",
      "username": "riya",
      "avatarUrl": "https://...",
      "phone": "+919876543210",
      "isPublic": true,
      "isVerified": false,
      "status": "offline",
      "friendship": "none",
      "matchedContact": "+91 98765 43210"
    }
  ]
}
```

| `friendship` | Meaning | Suggested CTA |
|---|---|---|
| `none` | No relationship | "Add" |
| `friends` | Already connected | "Message" |
| `request_sent` | You sent a pending request | "Requested" (disabled) |
| `request_received` | They sent you one | "Accept" |

> `matchedContact` echoes back the **exact string you sent**, so you can map each result to its local address-book row without re-normalising.
> Users with no match are simply absent from the array — it's not padded to the input length.

### Errors

| Code | Message |
|---|---|
| `400` | `phones must be an array` |

---

## `PUT /users/profile`

Legacy profile update.

### Request

`name`, `username`, `bio`, `location`, `language`, `avatarUrl`, `isPublic`

### Response `200`

```json
{ "success": true, "data": { "...updated user, password excluded" } }
```

> **Prefer [`PATCH /auth/`](auth.md#patch-auth) instead.** This route runs schema validators (so a duplicate `username` surfaces as a `500` rather than a clean `400`) and can't touch privacy or notification settings.

---

## Friend requests

### `POST /users/friend-requests`

*Rate: 60 / 5 min.*

#### Request

```json
{ "receiverId": "66b1..." }
```

#### Response `201` (new) / `200` (re-sent after a previous rejection)

```json
{
  "success": true,
  "message": "Friend request sent",
  "data": {
    "_id": "66c2...",
    "sender": "66b0...",
    "receiver": "66b1...",
    "status": "pending",
    "source": "search",
    "message": null,
    "createdAt": "2026-08-14T09:12:33.000Z"
  }
}
```

**Side effects:** an in-app notification row, an FCM push, and a `friend_request_received` socket event to the receiver.

#### Errors

| Code | Message |
|---|---|
| `400` | `receiverId is required` · `You cannot send a friend request to yourself` · `You are already friends` · `Friend request is already pending` |
| `403` | `You cannot send a friend request to this user` (blocked either way) |
| `404` | `Receiver user not found` |

---

### `GET /users/friend-requests/pending`

#### Response `200`

```json
{
  "success": true,
  "data":     [ "…legacy alias for incoming…" ],
  "incoming": [
    {
      "_id": "66c2...", "status": "pending", "createdAt": "...",
      "sender": { "_id": "...", "name": "...", "username": "...", "email": "...", "avatarUrl": "...", "status": "online", "isVerified": false },
      "receiver": "66b0..."
    }
  ],
  "outgoing": [
    {
      "_id": "66c3...", "status": "pending", "createdAt": "...",
      "sender": "66b0...",
      "receiver": { "_id": "...", "name": "...", "username": "...", "email": "...", "avatarUrl": "...", "status": "offline", "isVerified": false }
    }
  ]
}
```

> **Only the other party is populated, and which one flips with direction.** `incoming` populates `sender` and leaves `receiver` a bare id string; `outgoing` does the reverse. Both fields are always present, so `sender ?? receiver` picks the id string on outgoing requests — truthy, and it renders as "Unknown". Read `sender` on `incoming` and `receiver` on `outgoing`, keyed on which list you are in.

> Use `incoming` / `outgoing`. The top-level `data` key is a **legacy alias for `incoming`** kept for older clients — don't build new code against it.

---

### `PUT /users/friend-requests/:id`

Accept or reject. **Only the receiver may call this.**

#### Request

```json
{ "status": "accepted" }
```

`status` ∈ `accepted` | `rejected`

#### Response `200`

```json
{
  "success": true,
  "message": "Friend request accepted",
  "data": {
    "_id": "66c2...", "sender": "...", "receiver": "...",
    "status": "accepted",
    "chatId": "66d4...",
    "createdAt": "..."
  }
}
```

> On `accepted` a direct chat is created (or an existing one reused) and returned as **`chatId`** — open that conversation straight away instead of calling `POST /chat/conversations`.
> The original sender gets a `friend_request_updated` socket event plus a push.

#### Errors

| Code | Message |
|---|---|
| `400` | `Invalid status. Must be accepted or rejected` · `Friend request already accepted` / `already rejected` |
| `403` | `Not authorized to update this friend request` |
| `404` | `Friend request not found` |

---

### `GET /users/friends`

#### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66b1...", "name": "riya kapoor", "username": "riya",
      "email": "riya@example.com", "avatarUrl": "https://...",
      "status": "online", "isVerified": false,
      "chatId": "66d4..."
    }
  ]
}
```

> `chatId` is `null` for friendships created before chat linking — fall back to `POST /chat/conversations` with `type: "direct"` in that case.

---

## Blocking

Blocking is stored one-directionally but takes effect **both ways**: neither side can message, call, see stories, or fetch the other's profile.

| Method | Path | Body | Response `200` |
|---|---|---|---|
| `GET` | `/users/blocked` | — | `{ success, data: [ {_id, name, username, email, avatarUrl, status, isVerified} ] }` |
| `POST` | `/users/block/:id` | — | `{ success, message: "User blocked" }` |
| `POST` | `/users/unblock/:id` | — | `{ success, message: "User unblocked" }` |

### Errors

| Code | Message |
|---|---|
| `400` | `You cannot block yourself` |
| `404` | `User not found` (block only) |

> `unblock` is idempotent and returns `200` even if the user wasn't blocked.

---

## Nearby (proximity discovery)

Opt-in feature for discovering strangers physically near you.

**Privacy model:** positions are snapped to a coarse grid (~110 m), stored in Redis, and expire after **30 minutes** of inactivity. Other users never receive coordinates — only a coarse `tier`.

### `PATCH /users/nearby/settings`

*Rate: 20 / 5 min per user.* Master on/off switch.

#### Request

```json
{ "enabled": true }
```

#### Response `200`

```json
{ "success": true, "data": { "nearbyEnabled": true } }
```

> Setting `false` immediately erases the stored position **and** the record of peers you were shown — after that you can no longer send nearby requests to people you saw earlier.

---

### `POST /users/nearby/heartbeat`

*Rate: 30/min.* Call every ~30 s while the Nearby screen is open. Updates your position and returns who's around.

#### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `lat` | number | ❌ | Omit both to re-read peers without updating your position |
| `lng` | number | ❌ | |

```json
{ "lat": 12.9716, "lng": 77.5946 }
```

#### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66b1...",
      "name": "riya kapoor",
      "username": "riya",
      "avatarUrl": "https://...",
      "isVerified": false,
      "tier": "right_here"
    }
  ]
}
```

| `tier` | Distance | Suggested label |
|---|---|---|
| `right_here` | ≤ 120 m | "Right here" |
| `very_close` | ≤ 350 m | "Very close" |
| `nearby` | ≤ 500 m (default radius) | "Nearby" |

Sorted closest-tier first, **max 60 results**.

**Excluded from results:** yourself · anyone with Nearby off · anyone blocked either way · anyone you already have a friend request or friendship with.

> `avatarUrl` is `""` unless that user's `profilePhotoVisibility` is `Everyone`.
> An empty array is normal and common — show an "looking around…" state, not an error.

#### Errors

| Code | Message |
|---|---|
| `400` | `Invalid coordinates` (out of range, or exactly `0,0`) |
| `403` | `Nearby is turned off for this account` |
| `404` | `User not found` |

---

### `POST /users/nearby/ping`

*Rate: 20 / 5 min.* Fire-and-forget position update. Call on app foreground, and whenever you receive a `nearby_locate` silent push ([push-notifications.md](push-notifications.md#nearby-locate--silent)).

#### Request

```json
{ "lat": 12.9716, "lng": 77.5946 }
```

#### Response `200`

```json
{ "success": true, "data": { "recorded": true } }
```

#### Errors

| Code | Message |
|---|---|
| `400` | `Invalid coordinates` |
| `403` | `Nearby is turned off for this account` |

---

### `POST /users/nearby/request`

Send a one-line connection request to someone you saw in your Nearby list.

**Rate: 5 per day, per user** — a failed attempt is refunded, so only successful sends count against the quota.

#### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `userId` | string | ✅ | Must be someone currently in your nearby-peers set |
| `message` | string | ✅ | 1–200 characters |

```json
{ "userId": "66b1...", "message": "Hey, we're at the same cafe" }
```

#### Response `200`

```json
{
  "success": true,
  "data": {
    "_id": "66c5...",
    "status": "pending",
    "createdAt": "2026-08-14T09:12:33.000Z",
    "sender": { "_id": "66b0...", "name": "amit sharma", "username": "amit", "avatarUrl": "https://..." }
  }
}
```

This creates a normal friend request with `source: "nearby"` and the message attached, so it shows up in the receiver's `GET /users/friend-requests/pending`.

#### Errors

| Code | Message | Meaning |
|---|---|---|
| `400` | `receiverId is required` · `You cannot send a request to yourself` | |
| `400` | `A message is required` · `Message must be 200 characters or fewer` | |
| `400` | `You are already connected` · `A request is already pending` | |
| `403` | `That person is no longer nearby` | They moved away, went offline, or turned Nearby off — refresh the list |
| `403` | `You cannot send a request to this user` | Blocked, or a previous request was rejected |
| `404` | `User not found` | |
| `429` | Daily quota exhausted | Show remaining-quota state in the UI |
