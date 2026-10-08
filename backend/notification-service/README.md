# notification-service

Go worker that sends FCM push notifications, email, and SMS. It consumes
jobs the Node backend publishes onto RabbitMQ instead of sending them inline
on the request path.

## Why a separate service

Sending a push/email/SMS on the request path means every API call that
triggers one pays for the third-party round-trip, and a slow or down
provider can back up the whole backend. Publishing a small JSON job to
RabbitMQ instead is a fire-and-forget, sub-millisecond operation — this
service does the actual sending, with its own retry/backoff independent of
the request that triggered it.

## Channels

| Channel | Routing key | Send via |
|---|---|---|
| FCM push | `notification.fcm` | Firebase Admin SDK, same service account as the Node backend's `fcmService.js` |
| Mail | `notification.mail` | Plain SMTP (works with Gmail, SES-SMTP, Mailgun-SMTP, etc.) |
| SMS | `notification.sms` | [Fast2SMS](https://www.fast2sms.com) HTTP API |

**Scope note:** this ports `fcmService.js`'s general `sendPushNotification`
(chat messages, misc alerts). Call-specific VoIP pushes
(`sendCallNotification` / `sendCallEndedNotification`, with their
CallKit/Full-Screen-Intent payload shapes) stay in the Node backend — folding
those into this job schema risked silently changing call-notification
behavior for a shape different enough to warrant its own job type later.

## Message contract

Publish JSON to the `notifications` topic exchange with the routing key
above. See `internal/messages/messages.go` for the exact structs; the Node
side lives in `src/services/notificationQueue.js`.

```jsonc
// notification.fcm
{ "token": "...", "title": "...", "body": "...", "data": {"key": "value"} }

// notification.mail
{ "to": "user@example.com", "subject": "...", "body": "...", "isHtml": false }

// notification.sms
{ "to": "+919876543210", "message": "..." }
```

## Reliability

Failed jobs aren't dropped or retried forever — see the topology diagram in
`internal/queue/rabbitmq.go`. In short: a failed job waits 30s in a per-channel
retry queue, then comes back for another attempt; after `MAX_RETRIES` (default
5) it's moved to that channel's `<channel>_queue.dlq` for manual inspection
instead of retried indefinitely.

## Config

Copy `.env.example` to `.env` and fill in real credentials. In Docker Compose
this container mounts the repo's `credentials/` directory read-only for the
Firebase service account — no separate copy needed.

## Running locally (without Docker)

```bash
go run ./cmd/worker
```

Needs a reachable RabbitMQ (`docker compose up -d rabbitmq` from the repo
root is the easiest way) and the env vars from `.env.example` exported.

## Health check

`GET :8080/healthz` (port via `HEALTH_PORT`) — returns 200 once the process
is up. Doesn't check RabbitMQ/SMTP/Fast2SMS connectivity, just liveness.
