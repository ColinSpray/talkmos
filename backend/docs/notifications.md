# Notifications API

Base path: `/api/v1/notifications`

> Shared conventions — auth header, error envelope, status codes: **[README.md](README.md)**
> **All endpoints in this module require 🔒 `Authorization: Bearer <jwt>`.**

This is the **in-app notification inbox** — a persisted list the user can scroll and clear. It is separate from FCM push delivery (see [push-notifications.md](push-notifications.md)), though most events write to both.

---

## Routes at a glance

| Method | Path | Purpose |
|---|---|---|
| `GET` | [`/`](#get-notifications) | List all notifications |
| `POST` | [`/:id/read`](#post-notificationsidread) | Mark one read |
| `POST` | [`/read-all`](#post-notificationsread-all) | Mark all read |
| `DELETE` | [`/:id`](#delete-notificationsid) | Delete one |
| `POST` | [`/trigger`](#post-notificationstrigger) | **Dev helper** — create a fake notification |

> **Route order:** `/read-all` and `/trigger` are registered before `/:id/read`, so they're never captured by it.

---

## The notification object

```json
{
  "_id": "66g1...",
  "userId": "66b0...",
  "type": "friend_request",
  "title": "New Friend Request",
  "body": "riya kapoor sent you a friend request",
  "metadata": { "friendRequestId": "66c2...", "senderId": "66b1..." },
  "isRead": false,
  "readAt": null,
  "createdAt": "2026-08-14T09:12:33.000Z",
  "updatedAt": "2026-08-14T09:12:33.000Z"
}
```

### `type` values and their `metadata`

| `type` | Written when | `metadata` keys | Tap action |
|---|---|---|---|
| `friend_request` | Someone sends you a friend request (incl. Nearby) | `friendRequestId`, `senderId`, `source` (nearby only) | Open Friend Requests |
| `friend_request_accepted` | Your request was accepted | `friendRequestId`, `responderId` | Open the new chat |
| `system` | Admin broadcast | `imageUrl` (optional) | Show in-app |
| `message` | Reserved | — | Open chat |
| `call` | Reserved | — | Open call log |
| `story` | Reserved | — | Open story |
| `community` | Reserved | — | Open community |
| `event` | Reserved | — | Open event |

> `message`, `call`, `story`, `community` and `event` are valid schema values but are **not currently written by any backend flow** — chat and call alerts go out as FCM pushes only. Don't build the message list off this inbox.

---

## `GET /notifications`

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "_id": "66g1...", "userId": "66b0...",
      "type": "friend_request",
      "title": "New Friend Request",
      "body": "riya kapoor sent you a friend request",
      "metadata": { "friendRequestId": "66c2...", "senderId": "66b1..." },
      "isRead": false, "readAt": null,
      "createdAt": "...", "updatedAt": "..."
    }
  ]
}
```

Newest first.

> ⚠️ **Unpaginated** — this returns the user's entire notification history in one response. Cap the rendered list client-side (e.g. slice to the most recent 100) and consider deleting read items periodically.
> **Unread badge** = count of entries with `isRead === false`.

---

## `POST /notifications/:id/read`

Mark one notification read. No body.

### Response `200`

```json
{ "success": true, "data": { "...notification, isRead: true" } }
```

### Errors

| Code | Message |
|---|---|
| `404` | `Notification not found` (also returned if it belongs to another user) |

> The response does **not** set `readAt` — only `isRead`. Don't rely on `readAt` being populated.

---

## `POST /notifications/read-all`

Mark every unread notification read. No body.

### Response `200`

```json
{ "success": true, "message": "All notifications marked as read" }
```

Returns `200` even when there was nothing unread — safe to call on inbox open.

---

## `DELETE /notifications/:id`

### Response `200`

```json
{ "success": true, "message": "Notification deleted successfully" }
```

### Errors

| Code | Message |
|---|---|
| `404` | `Notification not found` |

> There is no bulk-delete endpoint. To clear the inbox, call this per id.

---

## `POST /notifications/trigger`

**Development / QA helper.** Creates an inbox row for the calling user. It does **not** send a push notification, despite the name.

### Request

| Field | Type | Required |
|---|---|---|
| `type` | enum (see table above) | ✅ |
| `title` | string | ✅ |
| `body` | string | ✅ |
| `metadata` | object | ❌ |

```json
{ "type": "system", "title": "Test", "body": "Hello from QA", "metadata": { "foo": "bar" } }
```

### Response `201`

```json
{ "success": true, "data": { "...notification" } }
```

### Errors

| Code | Message |
|---|---|
| `400` | `Type, Title, and Body are required` |
| `500` | Invalid `type` (schema enum violation) |

> Don't ship UI that calls this. To test real pushes, use the admin broadcast endpoint ([admin.md](admin.md#post-adminnotificationsbroadcast)).
