# Enums & Object Shapes

> Shared conventions: **[README.md](README.md)**

Every enum value the API accepts or returns, plus the canonical shape of the core objects.

---

## <a id="user-object"></a>User object

Returned in full by [`GET /auth/`](auth.md#get-auth) and [`PATCH /auth/`](auth.md#patch-auth). Other endpoints return subsets.

```json
{
  "_id": "66b0...",
  "name": "amit sharma",
  "username": "amit",
  "email": "amit@example.com",
  "phone": "+919876543210",

  "avatarUrl": "https://gcdn.ahamcloudservices.com/talkmostest/media/...",
  "bio": "building things",
  "location": "Bengaluru",
  "language": "en",

  "status": "online",
  "lastSeenAt": "2026-08-14T09:12:33.000Z",

  "notificationsEnabled": true,
  "notificationPreviewEnabled": true,

  "readReceiptsEnabled": true,
  "lastSeenVisibility": "Everyone",
  "profilePhotoVisibility": "Everyone",

  "nearbyEnabled": false,
  "nearbyLastOn": null,

  "isBlocked": ["66b9..."],

  "isVerified": false,
  "isPremium": false,
  "premiumExpiry": null,

  "role": "user",
  "isPublic": true,
  "authProvider": "local",

  "createdAt": "2026-08-01T10:00:00.000Z",
  "updatedAt": "2026-08-14T09:12:33.000Z"
}
```

**Notes**

* `name` is stored **lowercased** — apply display casing client-side.
* `password` is never returned by any endpoint.
* `isBlocked` is an array of user ids **you** have blocked. It's only present on your own profile, never on other users'.
* `lastKnownLocation` exists on the model but is never returned by any API response.
* `phoneSuffix` is an internal contact-matching field and is not part of the public contract.

---

## Message object

```json
{
  "_id": "66f0...",
  "chatId": "66d4...",
  "senderId": { "_id": "66b1...", "name": "riya kapoor", "avatarUrl": "https://..." },
  "messageType": "text",
  "content": "hey",
  "media": {
    "url": "", "thumbnail": "", "fileName": "",
    "mimeType": "", "size": 0, "duration": 0
  },
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
  "updatedAt": "2026-08-14T09:12:33.000Z"
}
```

`GET /chat/conversations/:id/messages` adds two computed fields: `reactions[]` and `isStarred`.

`media.duration` is in **seconds**; `media.size` in **bytes**.

---

## <a id="message-types"></a>Message types

`messageType` on a message.

| Value | Notes |
|---|---|
| `text` | Default; `content` carries the body |
| `image` | `media.url` + `media.thumbnail` |
| `video` | `media.url`, `media.thumbnail`, `media.duration` |
| `audio` | Music/audio file |
| `voice` | Voice note — render as a waveform player |
| `file` | Generic document; use `media.fileName` + `media.mimeType` |
| `gif` | |
| `sticker` | |
| `location` | Coordinates in `content` |
| `contact` | vCard/contact payload in `content` |
| `system` | Server-generated notice — render centred, no bubble |

> Only `text` messages can be edited.

---

## Message status

`status` on a message. Progresses forward only.

| Value | Meaning | UI |
|---|---|---|
| `sending` | Client-side only | Clock icon |
| `sent` | Persisted on the server | Single tick |
| `delivered` | Reached at least one recipient device | Double tick |
| `read` | Recipient opened the thread | Blue double tick |
| `failed` | Client-side only | Retry affordance |

> `read` is **not** set when the reader has `readReceiptsEnabled: false` — see [`PATCH /chat/conversations/:id/read`](chat.md#patch-chatconversationsidread).

---

## Chat types

| Value | Description |
|---|---|
| `direct` | 1:1 DM. Has `sender` + `receiver`, no Space. |
| `group` | Private group backed by a Space. |
| `community` | Public channel backed by a Space. **Not** listed in `/conversations`. |

---

## Member roles

`role` on a ChatMember, ascending in privilege.

| Value | Can |
|---|---|
| `member` | Read, send (subject to permissions) |
| `moderator` | Same as member — **not currently granted any extra rights by the backend** |
| `admin` | Add/remove members, edit info, change permissions |
| `owner` | Everything, plus delete the group. Cannot be removed or leave a community. |

> Permission checks accept **`owner` and `admin` only**. `moderator` is stored but behaves like `member`.

---

## Group permissions

`permissions` on a Chat. Each key is `"everyone"` or `"admins"`.

| Key | Default | Controls |
|---|---|---|
| `sendMessages` | `everyone` | Who can post |
| `editInfo` | `admins` | Who can rename / re-image |
| `addMembers` | `admins` | Who can add people |

---

## Call status

| Value | Meaning |
|---|---|
| `ringing` | Created, waiting for someone to answer |
| `ongoing` | At least one callee joined |
| `ended` | Completed normally |
| `missed` | Nobody but the initiator ever joined |
| `declined` | Callee explicitly rejected (1:1 only) |
| `failed` | Technical failure, reported by the client |

**Terminal statuses:** `ended`, `missed`, `declined`, `failed`. Joining a call in any of these returns `410`.

---

## Call participant status

| Value | Meaning |
|---|---|
| `invited` | Added but not yet notified |
| `ringing` | Actively being notified |
| `joined` | Currently connected |
| `declined` | Explicitly rejected |
| `missed` | Never responded before the call ended |
| `left` | Joined, then disconnected |
| `busy` | Was already on another call |

---

## User presence status

`status` on a User.

`online` · `offline` · `away` · `busy`

> This is a **stored profile field**, not live presence. For real presence use the socket event `is_user_online` ([realtime.md](realtime.md#wschat)).

---

## Visibility values

Used by `lastSeenVisibility` and `profilePhotoVisibility`.

| Value | Who can see |
|---|---|
| `Everyone` | Anyone (default) |
| `Contacts` | Accepted friends only |
| `Nobody` | Nobody |

> ⚠️ **Capitalised exactly like this.** Lowercase values are rejected with `400`.

---

## Auth providers

`authProvider` on a User.

| Value | Set by |
|---|---|
| `local` | Email + password registration (default) |
| `google` | Google sign-in |
| `phone` | Phone OTP |
| `apple` | Reserved — no endpoint yet |
| `facebook` | Reserved — no endpoint yet |

> An existing `local` account that signs in with Google is upgraded to `google`.

---

## Story visibility

| Value | Who can see |
|---|---|
| `friends` | Accepted friends only (default) |
| `public` | Anyone; also appears in `/stories/discover` |

## Story media types

`image` · `video`

---

## Notification types

| Value | Currently written? |
|---|---|
| `friend_request` | ✅ |
| `friend_request_accepted` | ✅ |
| `system` | ✅ (admin broadcast) |
| `message` | ❌ reserved |
| `call` | ❌ reserved |
| `story` | ❌ reserved |
| `community` | ❌ reserved |
| `event` | ❌ reserved |

---

## Friend request status & source

**`status`** · `pending` · `accepted` · `rejected`

**`source`** · `search` (default) · `contacts` · `nearby` · `link`

> `message` is only populated for `source: "nearby"` (max 200 chars); it is `null` for every other source.

---

## Device platforms

`ios` · `android` · `web` · `other` (default)

---

## Meeting

**`type`** · `instant` · `scheduled`
**`status`** · `scheduled` · `ongoing` · `ended`

> `POST /chat/meetings` sets `status: "ongoing"` for `instant` and `"scheduled"` for `scheduled`.

---

## Nearby tiers

Returned by [`POST /users/nearby/heartbeat`](users.md#post-usersnearbyheartbeat).

| Value | Distance | Suggested label |
|---|---|---|
| `right_here` | ≤ 120 m | "Right here" |
| `very_close` | ≤ 350 m | "Very close" |
| `nearby` | ≤ 500 m | "Nearby" |

> Thresholds are server-configurable — read the tier, never compute distance yourself.

---

## Contact match friendship states

Returned by [`POST /users/contacts/match`](users.md#post-userscontactsmatch).

`none` · `friends` · `request_sent` · `request_received`

---

## Admin broadcast targets

`all` · `premium` · `verified` · `unverified` · `user` (requires `userId`)
