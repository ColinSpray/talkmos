"use client";

import { useCallback, useEffect, useState } from "react";
import { api, apiErrorMessage } from "@/app/admin/_lib/api";
import { GlassCard } from "@/app/admin/_components/GlassCard";
import { Spinner } from "@/app/admin/_components/Spinner";
import { Pagination } from "@/app/admin/_components/Pagination";
import { ConfirmDialog } from "@/app/admin/_components/ConfirmDialog";
import { Button } from "@/app/admin/_components/Button";
import { Badge } from "@/app/admin/_components/Badge";
import type { AdminStory, Pagination as PaginationInfo } from "@/app/admin/_lib/types";

export function StoriesTab() {
  const [items, setItems] = useState<AdminStory[]>([]);
  const [pagination, setPagination] = useState<PaginationInfo | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pendingDelete, setPendingDelete] = useState<AdminStory | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    api
      .get("/admin/stories", { params: { page, limit: 20 } })
      .then(({ data }) => {
        setItems(data.data);
        setPagination(data.pagination);
      })
      .catch((err) => setError(apiErrorMessage(err, "Failed to load stories")))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load]);

  async function confirmDelete() {
    if (!pendingDelete) return;
    const id = pendingDelete._id;
    setBusyId(id);
    try {
      await api.delete(`/admin/stories/${id}`);
      setItems((prev) => prev.filter((s) => s._id !== id));
    } catch (err) {
      setError(apiErrorMessage(err, "Failed to delete story"));
    } finally {
      setBusyId(null);
      setPendingDelete(null);
    }
  }

  return (
    <div>
      {error && (
        <p className="mb-4 rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
          {error}
        </p>
      )}

      {loading ? (
        <div className="flex justify-center py-12">
          <Spinner />
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {items.map((s) => (
            <GlassCard key={s._id} className="overflow-hidden">
              <div className="aspect-[9/16] w-full overflow-hidden bg-black/30">
                {s.mediaType === "image" ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={s.mediaUrl}
                    alt={s.caption || "story"}
                    className="h-full w-full object-cover"
                  />
                ) : (
                  <video src={s.mediaUrl} className="h-full w-full object-cover" muted />
                )}
              </div>
              <div className="p-3">
                <p className="truncate text-sm font-medium text-white">
                  {s.userId?.name || "—"}
                </p>
                <div className="mt-1 flex flex-wrap gap-1">
                  <Badge tone={s.visibility === "public" ? "info" : "neutral"}>
                    {s.visibility}
                  </Badge>
                  {s.category && <Badge>{s.category}</Badge>}
                </div>
                <p className="mt-1 text-xs text-slate-400">
                  {new Date(s.createdAt).toLocaleString()}
                </p>
                <Button
                  variant="danger"
                  className="mt-3 w-full justify-center py-1.5 text-xs"
                  disabled={busyId === s._id}
                  onClick={() => setPendingDelete(s)}
                >
                  Delete
                </Button>
              </div>
            </GlassCard>
          ))}
          {items.length === 0 && (
            <p className="col-span-full py-10 text-center text-slate-400">
              No stories found.
            </p>
          )}
        </div>
      )}

      {pagination && (
        <GlassCard className="mt-4">
          <Pagination
            page={pagination.page}
            pages={pagination.pages}
            total={pagination.total}
            onChange={setPage}
          />
        </GlassCard>
      )}

      <ConfirmDialog
        open={!!pendingDelete}
        title="Delete this story?"
        description="This permanently removes the story."
        confirmLabel="Delete"
        onConfirm={confirmDelete}
        onCancel={() => setPendingDelete(null)}
      />
    </div>
  );
}
