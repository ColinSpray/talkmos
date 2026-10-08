/**
 * Deep links into Grafana's Loki explorer.
 *
 * The panel does not query Loki itself — it hands off to Grafana, which
 * already has the log UI, the auth and the datasource wiring. Everything here
 * is URL construction, so no extra dependency.
 *
 * Reachability matters: Grafana is published on 127.0.0.1:6002 of the server
 * running Compose, so these links resolve only from a browser that can reach
 * that address — the server itself, an SSH tunnel, or a reverse proxy. The
 * address itself is resolved in grafana.server.ts and passed in as a prop.
 */
/** Compose service names, as Alloy labels them from Docker metadata. */
export const LOG_SERVICES = [
  "backend",
  "notification-service",
  "mongo",
  "redis",
  "rabbitmq",
  "livekit",
  "loki",
  "alloy",
  "grafana",
] as const;

const ERROR_PATTERN = `(?i)(error|fatal|panic|exception)`;

/**
 * Grafana Explore takes its state as a JSON blob in the `panes` query param
 * (schemaVersion 1, Grafana 10+). This is the shape Explore itself produces
 * when you copy a URL out of it.
 */
export function exploreUrl(
  baseUrl: string,
  query: string,
  rangeFrom = "now-1h",
): string {
  const panes = {
    log: {
      datasource: { type: "loki", uid: "loki" },
      queries: [
        {
          refId: "A",
          expr: query,
          queryType: "range",
          datasource: { type: "loki", uid: "loki" },
        },
      ],
      range: { from: rangeFrom, to: "now" },
    },
  };
  const params = new URLSearchParams({
    schemaVersion: "1",
    panes: JSON.stringify(panes),
    orgId: "1",
  });
  return `${baseUrl}/explore?${params.toString()}`;
}

/** LogQL for a single compose service, optionally narrowed to errors. */
export function serviceQuery(service: string, errorsOnly = false): string {
  const base = `{service="${service}"}`;
  // A line filter rather than `level="ERROR"`: Alloy only attaches `level` to
  // lines matching the backend's "[ERROR] ..." stdout format, so a label match
  // would silently return nothing for mongo, redis, rabbitmq and livekit.
  return errorsOnly ? `${base} |~ "${ERROR_PATTERN}"` : base;
}

export const ALL_ERRORS_QUERY = `{job="docker"} |~ "${ERROR_PATTERN}"`;

/**
 * The provisioned operational dashboard
 * (talkmos-backend/observability/grafana/dashboards/json/backend.json).
 * Its uid is fixed there, so this link is stable across redeploys.
 */
export function dashboardUrl(baseUrl: string): string {
  return `${baseUrl}/d/talkmos-backend?orgId=1`;
}
