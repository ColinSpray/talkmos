# Auth API

Base path: `/api/v1/auth`

> Shared conventions — auth header, error envelope, status codes, rate limits: **[README.md](README.md)**
> 🔒 = requires `Authorization: Bearer <jwt>`

---

## Routes at a glance

| Method | Path | Auth | Rate limit |
|---|---|---|---|
| `POST` | [`/register`](#post-authregister) | — | 10/min |
| `POST` | [`/login`](#post-authlogin) | — | 10/min |
| `POST` | [`/google`](#post-authgoogle) | — | 10/min |
| `POST` | [`/phone/send-otp`](#post-authphonesend-otp) | — | 5/15min |
| `POST` | [`/phone/verify-otp`](#post-authphoneverify-otp) | — | 10/15min |
| `POST` | [`/logout`](#post-authlogout) | 🔒 | — |
| `POST` | [`/forgot-password`](#post-authforgot-password) | — | 5/15min |
| `POST` | [`/reset-password`](#post-authreset-password) | — | 10/15min |
| `GET` | [`/`](#get-auth) | 🔒 | — |
| `PATCH` | [`/`](#patch-auth) | 🔒 | — |
| `PUT` | [`/fcm-token`](#put-authfcm-token) | 🔒 | — |
| `GET` | [`/devices`](#get-authdevices) | 🔒 | — |
| `DELETE` | [`/devices/:deviceId`](#delete-authdevicesdeviceid) | 🔒 | — |

---

## The `device` object

Send this on **every** login/register call. Without it the token has no device binding, push notifications can't be targeted, and `PUT /auth/fcm-token` will fail.

```json
{
  "deviceId": "stable-uuid-generated-once-per-install",
  "deviceName": "Pixel 8",
  "platform": "android",
  "fcmToken": "<firebase token>"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `deviceId` | string | ✅ | Generate once per install and persist it. Reusing it across logins keeps one session row. |
| `deviceName` | string | ❌ | Shown in the "Active devices" screen |
| `platform` | `ios` \| `android` \| `web` \| `other` | ❌ | Defaults to `other` |
| `fcmToken` | string | ❌ | Can be set later via `PUT /auth/fcm-token` |

> Max **15** device sessions per user — beyond that the oldest logged-out sessions are evicted.
> `fcmToken` is only overwritten when you actually send one, so a login without it never blanks the stored token.

---

## `POST /auth/register`

Email + password signup. *Rate: 10/min.*

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | ✅ | Stored lowercased |
| `password` | string | ✅ | Min 6 characters |
| `email` | string | ❌ | Lowercased + trimmed, must be unique |
| `device` | object | ❌ (recommended) | [See above](#the-device-object) |

```json
{
  "name": "Amit Sharma",
  "email": "amit@example.com",
  "password": "secret123",
  "device": { "deviceId": "a1b2c3", "deviceName": "Pixel 8", "platform": "android", "fcmToken": "..." }
}
```

### Response `201`

```json
{
  "success": true,
  "token": "eyJhbGciOi...",
  "user": {
    "_id": "66b1...",
    "name": "amit sharma",
    "email": "amit@example.com",
    "isVerified": false,
    "isPremium": false
  }
}
```

### Errors

| Code | Message |
|---|---|
| `400` | `Name is required` · `Password is required` · `Password must be at least 6 characters` · `Email already registered` |
| `403` | `New user registrations are currently disabled by the administrator` |
| `429` | Rate limited |

---

## `POST /auth/login`

*Rate: 10/min.*

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `email` | string | one of | Lowercased + trimmed |
| `username` | string | one of | Trimmed |
| `password` | string | ✅ | |
| `device` | object | ❌ (recommended) | [See above](#the-device-object) |

```json
{ "email": "amit@example.com", "password": "secret123", "device": { "deviceId": "a1b2c3" } }
```

### Response `200`

```json
{
  "success": true,
  "token": "eyJhbGciOi...",
  "user": {
    "_id": "66b1...", "name": "amit sharma", "email": "amit@example.com",
    "username": "amit", "phone": "+919876543210",
    "isVerified": false, "isPremium": false
  }
}
```

### Errors

| Code | Message |
|---|---|
| `400` | `Please provide email or username` |
| `401` | `Invalid credentials` |

> `401` is returned for both "no such user" and "wrong password" — deliberately indistinguishable. Don't try to branch on it.

---

## `POST /auth/google`

Google / Firebase sign-in. Creates the account on first use. *Rate: 10/min.*

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `idToken` | string | ✅ | Firebase ID token, verified server-side |
| `device` | object | ❌ (recommended) | [See above](#the-device-object) |

Identity comes from the verified token and nothing else — `name`, `email` and `picture` in the body are ignored. A missing token, or one that fails verification, is a `400`; there is no fallback path.

### Response `200`

```json
{
  "success": true,
  "token": "eyJhbGciOi...",
  "isNewUser": true,
  "user": {
    "_id": "66b1...", "name": "Amit Sharma", "email": "amit@gmail.com",
    "username": "", "phone": "",
    "isVerified": true, "isPremium": false,
    "avatarUrl": "https://lh3.googleusercontent.com/..."
  }
}
```

> **`isNewUser: true`** means "account just created **and** has no phone number yet" → route the user into onboarding. Existing users always get `false`.
> Google users are always `isVerified: true`, and an existing `local` account signing in with Google is upgraded to `authProvider: "google"`.

### Errors

| Code | Message |
|---|---|
| `400` | `Google ID token is required` · `Token verification failed: <reason>` · `Email address is required for Google login` |
| `403` | `New user registrations are currently disabled by the administrator` |

---

## `POST /auth/phone/send-otp`

Sends a 6-digit code by SMS, valid **10 minutes**. *Rate: 5 / 15 min.*

### Request

```json
{ "phone": "+919876543210" }
```

### Response `200`

```json
{ "success": true, "message": "Verification code sent", "devCode": "483920" }
```

> `devCode` is **only** present when the server runs with `OTP_AUTOFILL=true` (staging builds). Use it to autofill in dev; never depend on it in production.
> Sending a new code overwrites any previous unused one for that number.

### Errors

| Code | Message |
|---|---|
| `400` | `Phone number is required` · SMS provider error text |

---

## `POST /auth/phone/verify-otp`

Verifies the code, creates the account on first use, and logs in. *Rate: 10 / 15 min.*

### Request

| Field | Type | Required |
|---|---|---|
| `phone` | string | ✅ |
| `code` | string | ✅ |
| `device` | object | ❌ (recommended) |

### Response `200`

```json
{
  "success": true,
  "isNewUser": true,
  "token": "eyJhbGciOi...",
  "user": {
    "_id": "66b1...", "name": "", "username": "", "phone": "+919876543210",
    "email": "", "avatarUrl": "", "isVerified": false, "isPremium": false
  }
}
```

> **`isNewUser: true`** also fires for an *existing* account that never finished onboarding (missing `name` or `username`). Treat it purely as "show the profile-completion screen".
> A code can only be consumed once.

### Errors

| Code | Message |
|---|---|
| `400` | `Phone and code are required` · `Invalid or expired code` |

---

## `POST /auth/logout` 🔒

No body. Revokes the current device session (bumps its `tokenVersion`) and force-disconnects its live sockets on both namespaces.

### Response `200`

```json
{ "success": true, "message": "Logged out successfully" }
```

> If the token was minted without a `device`, this is a no-op that still returns `200`.

---

## `POST /auth/forgot-password`

Sends a reset code — by SMS when `phone` is given, by email otherwise. *Rate: 5 / 15 min.*

### Request

```json
{ "email": "amit@example.com" }
```
or
```json
{ "phone": "+919876543210" }
```

### Response `200`

```json
{ "success": true, "message": "Password reset code generated successfully", "devCode": "483920" }
```

> `devCode` appears only with `OTP_AUTOFILL=true` **and** a phone-based reset.

### Errors

| Code | Message |
|---|---|
| `404` | `User not found` |

---

## `POST /auth/reset-password`

*Rate: 10 / 15 min.*

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `email` or `phone` | string | ✅ | Must match the one used for `forgot-password` |
| `code` | string | ✅ | |
| `password` | string | ✅ | Min 6 characters |

### Response `200`

```json
{ "success": true, "message": "Password reset successfully" }
```

### Errors

| Code | Message |
|---|---|
| `400` | `Password must be at least 6 characters` · `Invalid or expired recovery code` |
| `404` | `User not found` |

---

## `GET /auth/` 🔒

Current user's full profile. Server-cached ~5 minutes; password excluded.

### Response `200`

```json
{ "success": true, "data": { "_id": "...", "name": "...", "email": "...", "...": "..." } }
```

Full field list: **[enums.md → User object](enums.md#user-object)**.

### Errors

| Code | Message |
|---|---|
| `404` | `User not found` |

---

## `PATCH /auth/` 🔒

Update profile + notification/privacy settings. **Send only the fields you're changing** — omitted fields are left untouched.

### Request

| Field | Type | Notes |
|---|---|---|
| `name` | string | |
| `username` | string | Must be unique |
| `phone` | string | Must be unique; send `""` to unlink |
| `avatarUrl` | string | |
| `bio` | string | |
| `location` | string | |
| `status` | `online` \| `offline` \| `away` \| `busy` | |
| `notificationsEnabled` | bool | Master push switch |
| `notificationPreviewEnabled` | bool | `false` → pushes show `"New message"` with no sender or content |
| `readReceiptsEnabled` | bool | `false` → your reads don't mark direct messages as read |
| `lastSeenVisibility` | `Everyone` \| `Contacts` \| `Nobody` | **Capitalised exactly like this** |
| `profilePhotoVisibility` | `Everyone` \| `Contacts` \| `Nobody` | |
| `isPublic` | bool | `false` → only friends can DM/call you |

### Response `200`

```json
{ "success": true, "data": { "...updated user, password excluded" } }
```

### Errors

| Code | Body |
|---|---|
| `409` | `{ "success": false, "code": "PHONE_ALREADY_LINKED", "message": "This phone number is already linked to another account. Log out and sign in with your phone number to access it." }` |
| `400` | `Username already taken` · `Invalid lastSeenVisibility value` · `Invalid profilePhotoVisibility value` |

> On `PHONE_ALREADY_LINKED`, surface the "log out and sign in with that number instead" flow — merging accounts is not supported.

---

## `PUT /auth/fcm-token` 🔒

Updates the Firebase push token for the **current device only**.

### Request

```json
{ "fcmToken": "dGhpcyBpcyBhIHRva2Vu..." }
```

### Response `200`

```json
{ "success": true, "message": "FCM Token updated successfully" }
```

### Errors

| Code | Message | Meaning |
|---|---|---|
| `400` | `FCM Token is required` | Field missing entirely |
| `400` | `This session has no device attached — please sign in again` | Token was minted without a `device` object |
| `404` | `Device session not found` | Session was deleted/evicted |

> Call this on app start **and** on every Firebase token refresh. Without it the user silently stops receiving pushes.

---

## `GET /auth/devices` 🔒

Active sessions plus recent logged-out history, most recently active first.

### Response `200`

```json
{
  "success": true,
  "data": [
    {
      "deviceId": "a1b2c3",
      "deviceName": "Pixel 8",
      "platform": "android",
      "isActive": true,
      "isCurrent": true,
      "loginAt": "2026-08-14T09:00:00.000Z",
      "lastActiveAt": "2026-08-14T09:12:33.000Z",
      "loggedOutAt": null
    }
  ]
}
```

> Use `isCurrent` to disable the "log out" button on the device you're on (or make it a full logout). Entries with `isActive: false` are history — render them dimmed or filter them out.

---

## `DELETE /auth/devices/:deviceId` 🔒

Remote logout of another device. Its live sockets are disconnected immediately with a `session_revoked` event.

### Response `200`

```json
{ "success": true, "message": "Device logged out" }
```

### Errors

| Code | Message |
|---|---|
| `404` | `Device not found` |
