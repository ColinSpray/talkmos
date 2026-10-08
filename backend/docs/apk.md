# APK / App Update API

Base path: `/api/v1/apk`

> Shared conventions — auth header, error envelope, status codes: **[README.md](README.md)**

Powers self-hosted Android distribution and the in-app force-update gate.

---

## Routes at a glance

| Method | Path | Auth |
|---|---|---|
| `GET` | [`/info`](#get-apkinfoversioncodeint) | **Public** |
| `GET` | [`/download`](#get-apkdownload) | **Public** |
| `POST` | [`/upload`](#post-apkupload) | 🔒 **admin only** |

---

## `GET /apk/info?versionCode=<int>` — public

Update check. **Call this on every app start**, before the user reaches the main screen.

### Query

| Param | Type | Required | Notes |
|---|---|---|---|
| `versionCode` | int | ❌ (send it) | The **installed** build's version code. Alias: `v`. Defaults to `1` if omitted — which will almost always report an update as available. |

### Response `200`

```json
{
  "success": true,
  "available": true,
  "hasUpdate": true,
  "latestVersionName": "1.1.1",
  "latestVersionCode": 10,
  "minRequiredVersionCode": 5,
  "isForceUpdate": false,
  "releaseNotes": "Fix the dark mode colours",
  "downloadUrl": "https://stage-api.talkmos.com/api/v1/apk/download",
  "fileSize": 48213402,
  "updatedAt": "2026-08-13T17:53:00.000Z"
}
```

| Field | Type | Meaning |
|---|---|---|
| `available` | bool | An APK file actually exists on the server |
| `hasUpdate` | bool | `available && latestVersionCode > yourVersionCode` |
| `latestVersionName` | string | Human-readable version, e.g. `"1.1.1"` |
| `latestVersionCode` | int | Numeric build number to compare against |
| `minRequiredVersionCode` | int | Below this, the app must update to keep working |
| `isForceUpdate` | bool | `true` when the admin forced it **or** your `versionCode < minRequiredVersionCode` |
| `releaseNotes` | string | Show in the update dialog |
| `downloadUrl` | string | Absolute URL (respects `x-forwarded-proto`) |
| `fileSize` | int | Bytes — show "48 MB" in the dialog |
| `updatedAt` | ISO date | When the APK file was last written |

### Client logic

```
if (!available)            → skip the check entirely
else if (isForceUpdate)    → blocking, non-dismissible dialog → downloadUrl
else if (hasUpdate)        → dismissible "Update available" prompt → downloadUrl
else                       → continue to the app
```

> `isForceUpdate` already folds in the `minRequiredVersionCode` comparison — you don't need to evaluate that yourself.
> This is the **only** gate; there's no server-side blocking of old clients, so honour it.

### Errors

| Code | Message |
|---|---|
| `500` | Server error |

---

## `GET /apk/download` — public

Streams the APK as a file download.

**Response headers**

```http
Content-Type: application/vnd.android.package-archive
Content-Disposition: attachment; filename="talkmos.apk"
```

### Errors

| Code | Body |
|---|---|
| `404` | `{ "success": false, "message": "APK not found" }` |

> Only **one** APK is stored at a time — the latest upload overwrites the previous file. There's no per-version download URL.

---

## `POST /apk/upload` — 🔒 admin only

Uploads a new APK and updates the version metadata in one call. `multipart/form-data`.

### Request

| Field | Type | Required | Notes |
|---|---|---|---|
| `apk` | file | ✅ | Must be `application/vnd.android.package-archive` or end in `.apk` |
| `versionName` | string | ❌ | e.g. `"1.1.1"` |
| `versionCode` | int | ❌ | |
| `minRequiredVersionCode` | int | ❌ | |
| `releaseNotes` | string | ❌ | |
| `isForceUpdate` | bool \| `"true"`/`"false"` | ❌ | |

Omitted metadata fields keep their current values.

```bash
curl -X POST https://stage-api.talkmos.com/api/v1/apk/upload \
  -H "Authorization: Bearer <admin-jwt>" \
  -F "apk=@build/app/outputs/flutter-apk/app-release.apk" \
  -F "versionName=1.1.1" \
  -F "versionCode=10" \
  -F "minRequiredVersionCode=1" \
  -F "releaseNotes=Fix the dark mode colours" \
  -F "isForceUpdate=false"
```

### Response `200`

```json
{
  "success": true,
  "message": "APK uploaded & version updated successfully",
  "data": {
    "versionName": "1.1.1",
    "versionCode": 10,
    "minRequiredVersionCode": 1,
    "releaseNotes": "Fix the dark mode colours",
    "isForceUpdate": false,
    "downloadUrl": "https://stage-api.talkmos.com/api/v1/apk/download"
  }
}
```

### Errors

| Code | Message |
|---|---|
| `400` | `No APK file uploaded` |
| `403` | `Access denied: Administrative privileges required` |
| `500` | `Only APK files allowed` |

> The uploaded file always lands as `talkmos.apk`, replacing whatever was there. Version metadata is shared with `PATCH /admin/settings` — either endpoint can change it.
