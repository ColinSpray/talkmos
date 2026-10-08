import "server-only";

const DEFAULT_URL = "http://localhost:6002";

/**
 * Grafana's public address, read at request time.
 *
 * Deliberately not a NEXT_PUBLIC_ variable: Next.js inlines those into the
 * client bundle during `next build`, so editing .env changed nothing until the
 * app was rebuilt — and a stale localhost URL shipped inside the JS. Read here
 * on the server and passed down as a prop, a restart is enough.
 *
 * `configured` is false when nothing was set and the localhost default is in
 * play — the one case where the reachability help is worth showing.
 */
export function resolveGrafanaUrl(): { url: string; configured: boolean } {
  const raw = process.env.GRAFANA_URL ?? process.env.NEXT_PUBLIC_GRAFANA_URL;
  return {
    url: (raw ?? DEFAULT_URL).replace(/\/$/, ""),
    configured: Boolean(raw && raw.trim()),
  };
}
