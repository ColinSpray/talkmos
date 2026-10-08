"use client";

import { useCallback, useEffect, useState } from "react";
import { api, apiErrorMessage } from "@/app/admin/_lib/api";
import { GlassCard } from "@/app/admin/_components/GlassCard";
import { Badge } from "@/app/admin/_components/Badge";
import { Spinner } from "@/app/admin/_components/Spinner";
import { Pagination } from "@/app/admin/_components/Pagination";
import type { AuditLogEntry, Pagination as PaginationInfo } from "@/app/admin/_lib/types";

function methodTone(method: string) {
  switch (method) {
    case "DELETE":
      return "danger" as const;
    case "PATCH":
    case "PUT":
      return "warning" as const;
    case "POST":
      return "info" as const;
    default:
      return "neutral" as const;
  }
}

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [pagination, setPagination] = useState<PaginationInfo | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    api
      .get("/admin/audit-logs", { params: { page, limit: 50 } })
      .then(({ data }) => {
        setLogs(data.data);
        setPagination(data.pagination);
      })
      .catch((err) => setError(apiErrorMessage(err, "Failed to load audit logs")))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load]);

  return (
    <div>
      <h1 className="text-2xl font-semibold text-white">Audit Log</h1>
      <p className="mt-1 text-sm text-slate-400">
        Every admin action recorded against this API.
      </p>

      {error && (
        <p className="mt-4 rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
          {error}
        </p>
      )}

      <GlassCard className="mt-6 overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-12">
            <Spinner />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-white/10 text-xs uppercase tracking-wide text-slate-400">
                  <th className="px-4 py-3 font-medium">Admin</th>
                  <th className="px-4 py-3 font-medium">Method</th>
                  <th className="px-4 py-3 font-medium">Path</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium">IP</th>
                  <th className="px-4 py-3 font-medium">When</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => (
                  <tr
                    key={log._id}
                    className="border-b border-white/5 last:border-0 hover:bg-white/5"
                  >
                    <td className="px-4 py-3 text-slate-300">
                      {log.adminId?.name || log.adminEmail || "—"}
                    </td>
                    <td className="px-4 py-3">
                      <Badge tone={methodTone(log.method)}>{log.method}</Badge>
                    </td>
                    <td className="max-w-xs truncate px-4 py-3 font-mono text-xs text-slate-300">
                      {log.path}
                    </td>
                    <td className="px-4 py-3">
                      <Badge tone={log.statusCode >= 400 ? "danger" : "success"}>
                        {log.statusCode}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-400">{log.ipAddress}</td>
                    <td className="px-4 py-3 text-xs text-slate-400">
                      {new Date(log.createdAt).toLocaleString()}
                    </td>
                  </tr>
                ))}
                {logs.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-4 py-10 text-center text-slate-400">
                      No audit log entries yet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {pagination && (
          <Pagination
            page={pagination.page}
            pages={pagination.pages}
            total={pagination.total}
            onChange={setPage}
          />
        )}
      </GlassCard>
    </div>
  );
}
