# Translate API

Base path: `/api/v1/translate`

> Shared conventions — auth header, error envelope, status codes: **[README.md](README.md)**
> **All endpoints in this module require 🔒 `Authorization: Bearer <jwt>`.**

A thin proxy in front of an internal translation microservice. The backend adds authentication and normalises errors; it does not transform the payload.

---

## Routes at a glance

| Method | Path | Purpose |
|---|---|---|
| `POST` | [`/`](#post-translate) | Translate text |
| `GET` | [`/languages`](#get-translatelanguages) | List supported languages |

---

## `POST /translate`

Your request body is forwarded **verbatim** to the translation service's own `POST /translate`, so that service's field names apply (typically the text plus a target language).

### Request

```json
{ "text": "Good morning", "target": "hi", "source": "en" }
```

| Field | Required | Meaning |
|---|---|---|
| `text` | yes | Text to translate (max 5000 chars) |
| `target` | yes | Language code to translate into |
| `source` | no | Language code to translate from; omit to let the service detect it |

> These names belong to the upstream service, not to this backend — the body is forwarded verbatim, and anything extra is passed through untouched. Sending `targetLang` instead of `target` fails with `400 text and target are required`.

### Response `200`

```json
{ "success": true, "data": { "translatedText": "सुप्रभात" } }
```

Only `translatedText` is passed through — any other keys the upstream returns are dropped.

### Errors

| Code | Message | Meaning | Client action |
|---|---|---|---|
| `400` | *(upstream's `error` text)* | Bad input — missing field, unsupported language | Fix the request |
| `502` | `Translation service error` | Upstream returned a non-200 | Retry once, then give up |
| `503` | `Translation service is unavailable` | Upstream unreachable / timed out | Fall back to the original text |

---

## `GET /translate/languages`

### Response `200`

```json
{ "success": true, "data": { "...upstream language list, passed through unchanged" } }
```

The exact shape is whatever the translation service returns — treat it as opaque and render it directly.

### Errors

| Code | Message |
|---|---|
| `502` | `Translation service error` |
| `503` | `Translation service is unavailable` |

---

## Integration notes

* **Fail soft.** `502` and `503` are infrastructural and transient. Show the original untranslated text rather than an error banner — translation is an enhancement, not a blocking feature.
* **Cache language list.** It changes rarely; fetch once per session at most.
* **Debounce.** There's no rate limit on these routes today, but each call is a network hop to another service. Don't translate on every keystroke.
