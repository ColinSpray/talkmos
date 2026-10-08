# nginx — Grafana

`grafana.conf` is a complete nginx site, **HTTP-only on purpose**. certbot adds
the TLS half.

> Chat media is **not** served from this server. It lives on an external MinIO
> (`MINIO_ENDPOINT` in `.env`), which fronts itself — there is no vhost here
> for it and no certificate to issue.

## Why no 443 block in the file

`certbot --nginx` needs nginx already running and serving `server_name` on port
80 — that is how it answers the ACME challenge. A hand-written 443 block would
point at `/etc/letsencrypt/live/<domain>/fullchain.pem`, which does not exist
yet, so nginx would refuse to start and certbot would have nothing to work
with. Shipping HTTP-only avoids that deadlock.

certbot then rewrites this file in place: it adds the `listen 443 ssl` server,
the certificate paths, and the HTTP→HTTPS redirect, copying the `location`
blocks across unchanged.

## Setup

1. Point an A record for your name at this server.

2. Set the domain (it appears once in `server_name`, twice more in comments):

   ```bash
   sed -i 's/logs.talkmos.com/YOUR-DOMAIN/g' nginx/grafana.conf
   ```

3. Install and start it:

   ```bash
   sudo cp nginx/grafana.conf /etc/nginx/sites-available/grafana
   sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/
   sudo nginx -t && sudo systemctl reload nginx
   ```

4. Add TLS:

   ```bash
   sudo certbot --nginx -d YOUR-DOMAIN
   ```

   Port 80 must be reachable from the internet for the HTTP-01 challenge. If it
   is not (Cloudflare proxying, a firewall), use a DNS challenge instead —
   `certbot certonly --dns-<provider>` — and add the `listen 443 ssl` block by
   hand once the cert exists.

5. Backend `.env` — tell Grafana its public address:

   ```
   GRAFANA_ROOT_URL=https://YOUR-DOMAIN
   GRAFANA_COOKIE_SAMESITE=none
   GRAFANA_COOKIE_SECURE=true
   ```

   `samesite=none` is what keeps the admin panel's inline log pane logged in:
   the panel and Grafana are different origins, and a browser drops the cookie
   under `lax`. It is ignored unless `secure=true`, which the new certificate
   provides.

   ```bash
   docker compose up -d grafana
   ```

6. Admin panel `.env` — `NEXT_PUBLIC_GRAFANA_URL=https://YOUR-DOMAIN`, then
   **rebuild**: `NEXT_PUBLIC_` values are baked in at build time, so a restart
   alone will not pick it up.


## Loki is not proxied, deliberately

`observability/loki-config.yml` runs with `auth_enabled: false`: anything that
reaches port 6003 reads every log line with no credentials. Loki stays bound to
127.0.0.1 and is reached only by Grafana over the Compose network. Grafana's
login is the authentication boundary — do not add a location block for it.

## Verified

Run against a real nginx (1.30.4) with a stub upstream, with no certificates on
the machine:

- `nginx -t` passes with `/etc/letsencrypt` absent — the point of the HTTP-only
  shape
- paths reach the upstream unmodified (`/login`, `/public/build/app.js`)
- `Upgrade` / `Connection: upgrade` and the `X-Forwarded-*` headers forward

A websocket test over HTTP/2 shows no `Upgrade` header — that is the protocol,
not the config. HTTP/2 forbids it, and browsers open `wss://` over HTTP/1.1
regardless of the page's protocol, so Grafana Live works once certbot has
enabled HTTP/2 on 443.
