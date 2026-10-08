"use client";

import { useEffect, useState } from "react";
import { api, apiErrorMessage } from "@/app/admin/_lib/api";
import { StatTile } from "@/app/admin/_components/StatTile";
import { Spinner } from "@/app/admin/_components/Spinner";
import type { Stats } from "@/app/admin/_lib/types";

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    api
      .get("/admin/stats")
      .then(({ data }) => {
        if (!cancelled) setStats(data.data);
      })
      .catch((err) => {
        if (!cancelled) setError(apiErrorMessage(err, "Failed to load stats"));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div>
      <h1 className="text-2xl font-semibold text-white">Dashboard</h1>
      <p className="mt-1 text-sm text-slate-400">
        A snapshot of what&apos;s happening across Talkmos.
      </p>

      {loading && (
        <div className="mt-10 flex justify-center">
          <Spinner />
        </div>
      )}

      {error && (
        <p className="mt-6 rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
          {error}
        </p>
      )}

      {stats && (
        <div className="mt-6 space-y-6">
          <div>
            <h2 className="mb-3 text-sm font-medium uppercase tracking-wide text-slate-400">
              Users
            </h2>
            <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
              <StatTile label="Total users" value={stats.users.total} />
              <StatTile label="Premium" value={stats.users.premium} />
              <StatTile label="Verified" value={stats.users.verified} />
              <StatTile label="Admins" value={stats.users.admin} />
            </div>
          </div>

          <div>
            <h2 className="mb-3 text-sm font-medium uppercase tracking-wide text-slate-400">
              Activity
            </h2>
            <div className="grid grid-cols-2 gap-4 md:grid-cols-3">
              <StatTile label="Messages" value={stats.stats.messages} />
              <StatTile label="Chats" value={stats.stats.chats} />
              <StatTile label="Calls" value={stats.stats.calls} />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
