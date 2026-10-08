import { resolveGrafanaUrl } from "../../_lib/grafana.server";
import LogsView from "./LogsView";

// Read the Grafana address at request time rather than at build time.
//
// Without this the page is prerendered and process.env is evaluated once,
// during `next build` — which is how a stale http://localhost:6002 ended up
// baked into the shipped bundle even after .env had been updated.
export const dynamic = "force-dynamic";

export default function LogsPage() {
  const { url, configured } = resolveGrafanaUrl();
  return <LogsView grafanaUrl={url} configured={configured} />;
}
