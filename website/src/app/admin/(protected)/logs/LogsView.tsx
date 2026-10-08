"use client";

import { useMemo, useState } from "react";
import { GlassCard } from "../../_components/GlassCard";
import { Button } from "../../_components/Button";
import { Badge } from "../../_components/Badge";
import {
  ALL_ERRORS_QUERY,
  LOG_SERVICES,
  dashboardUrl,
  exploreUrl,
  serviceQuery,
} from "../../_lib/grafana";

const RANGES = [
  { label: "15m", value: "now-15m" },
  { label: "1h", value: "now-1h" },
  { label: "6h", value: "now-6h" },
  { label: "24h", value: "now-24h" },
  { label: "7d", value: "now-7d" },
];

const ALL = "__all__";

function Code({ children }: { children: React.ReactNode }) {
  return (
    <code className="rounded bg-black/30 px-1.5 py-0.5 font-mono text-xs text-slate-200">
      {children}
    </code>
  );
}

export default function LogsView({
  grafanaUrl,
  configured,
}: {
  grafanaUrl: string;
  configured: boolean;
}) {
  const [service, setService] = useState<string>("backend");
  const [errorsOnly, setErrorsOnly] = useState(false);
  const [range, setRange] = useState("now-1h");
  const [embed, setEmbed] = useState(false);

  const query = useMemo(
    () => (service === ALL ? ALL_ERRORS_QUERY : serviceQuery(service, errorsOnly)),
    [service, errorsOnly],
  );
  const url = useMemo(
    () => exploreUrl(grafanaUrl, query, range),
    [grafanaUrl, query, range],
  );

  const chip = (active: boolean) =>
    `rounded-lg px-3 py-1.5 text-sm transition ${active ? "glass text-white" : "text-slate-300 hover:bg-white/5 hover:text-white"
    }`;

  return (
    <div>
      <h1 className="text-2xl font-semibold text-white">Logs</h1>
      <p className="mt-1 text-sm text-slate-400">
        Container logs are shipped to Loki and browsed in Grafana. Pick a scope
        and open it there.
      </p>

      <GlassCard className="mt-6 space-y-5 p-5">
        <div>
          <p className="mb-2 text-xs font-medium uppercase tracking-wide text-slate-400">
            Service
          </p>
          <div className="flex flex-wrap gap-2">
            <button onClick={() => setService(ALL)} className={chip(service === ALL)}>
              All services (errors)
            </button>
            {LOG_SERVICES.map((s) => (
              <button key={s} onClick={() => setService(s)} className={chip(service === s)}>
                {s}
              </button>
            ))}
          </div>
        </div>

        <div className="flex flex-wrap items-end gap-6">
          <div>
            <p className="mb-2 text-xs font-medium uppercase tracking-wide text-slate-400">
              Time range
            </p>
            <div className="flex gap-2">
              {RANGES.map((r) => (
                <button
                  key={r.value}
                  onClick={() => setRange(r.value)}
                  className={chip(range === r.value)}
                >
                  {r.label}
                </button>
              ))}
            </div>
          </div>

          {service !== ALL && (
            <label className="flex cursor-pointer items-center gap-2 pb-1.5 text-sm text-slate-300">
              <input
                type="checkbox"
                checked={errorsOnly}
                onChange={(e) => setErrorsOnly(e.target.checked)}
                className="h-4 w-4 rounded border-white/20 bg-transparent"
              />
              Errors only
            </label>
          )}
        </div>

        <div>
          <p className="mb-2 text-xs font-medium uppercase tracking-wide text-slate-400">
            Query
          </p>
          <code className="block overflow-x-auto rounded-lg bg-black/30 px-3 py-2 font-mono text-xs text-slate-200">
            {query}
          </code>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <a href={url} target="_blank" rel="noopener noreferrer">
            <Button>Open in Grafana ↗</Button>
          </a>
          <a href={dashboardUrl(grafanaUrl)} target="_blank" rel="noopener noreferrer">
            <Button variant="ghost">Backend dashboard ↗</Button>
          </a>
          <Button variant="ghost" onClick={() => setEmbed((v) => !v)}>
            {embed ? "Hide inline view" : "Show inline view"}
          </Button>
          <Badge tone="neutral">{grafanaUrl}</Badge>
        </div>
      </GlassCard>

      {embed && (
        <GlassCard className="mt-6 p-0">
          {/* Grafana refuses to be framed unless GF_SECURITY_ALLOW_EMBEDDING is
              on, and it is served from the host running Compose — so this pane
              stays blank when the browser cannot reach GRAFANA_URL. The link
              above is the path that always works. */}
          <iframe
            src={url}
            title="Grafana logs"
            className="h-[70vh] w-full rounded-2xl border-0"
          />
        </GlassCard>
      )}

      {/* Only worth showing while GRAFANA_URL is unset and the localhost
          default is in play. Once it points at the reverse proxy this is
          solved, and a permanent troubleshooting block is just noise. */}
      {!configured && (
        <GlassCard className="mt-6 border border-amber-400/30 p-5">
          <p className="text-sm font-medium text-amber-300">
            GRAFANA_URL is not set
          </p>
          <p className="mt-2 text-sm text-slate-400">
            Falling back to <Code>{grafanaUrl}</Code>, which only resolves from
            the server itself. Put Grafana behind the reverse proxy (see{" "}
            <Code>nginx/grafana.conf</Code> in the backend repo), then set{" "}
            <Code>GRAFANA_URL</Code> to that address — <Code>.env</Code> for the
            container, <Code>.env.local</Code> for local dev — and restart. No
            rebuild needed; it is read per request.
          </p>
          <p className="mt-2 text-sm text-slate-400">
            To reach it without a proxy in the meantime:{" "}
            <Code>ssh -L 6002:127.0.0.1:6002 &lt;host&gt;</Code>
          </p>
        </GlassCard>
      )}
    </div>
  );
}
