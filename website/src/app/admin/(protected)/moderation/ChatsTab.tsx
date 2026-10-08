"use client";

import { useCallback, useEffect, useState } from "react";
import { api, apiErrorMessage } from "@/app/admin/_lib/api";
import { GlassCard } from "@/app/admin/_components/GlassCard";
import { Spinner } from "@/app/admin/_components/Spinner";
import { Pagination } from "@/app/admin/_components/Pagination";
import { ConfirmDialog } from "@/app/admin/_components/ConfirmDialog";
import { Button } from "@/app/admin/_components/Button";
import { Badge } from "@/app/admin/_components/Badge";
import type { ChatSummary, Pagination as PaginationInfo } from "@/app/admin/_lib/types";

export function ChatsTab({ onOpenChat }: { onOpenChat?: (chatId: string) => void } = {}) {
  const [items, setItems] = useState<ChatSummary[]>([]);
  const [pagination, setPagination] = useState<PaginationInfo | null>(null);
  const [page, setPage] = useState(1);
  const [chatType, setChatType] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pendingDelete, setPendingDelete] = useState<ChatSummary | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    api
      .get("/admin/chats", { params: { page, limit: 20, chatType: chatType || undefined } })
      .then(({ data }) => {
        setItems(data.data);
        setPagination(data.pagination);
      })
      .catch((err) => setError(apiErrorMessage(err, "Failed to load chats")))
      .finally(() => setLoading(false));
  }, [page, chatType]);

  useEffect(load, [load]);

  async function confirmDelete() {
    if (!pendingDelete) return;
    const id = pendingDelete._id;
    setBusyId(id);
    try {
      await api.delete(`/admin/chats/${id}`);
      setItems((prev) => prev.filter((c) => c._id !== id));
    } catch (err) {
      setError(apiErrorMessage(err, "Failed to delete chat"));
    } finally {
      setBusyId(null);
      setPendingDelete(null);
    }
  }

  return (
    <div>
      <div className="flex gap-2">
        {["", "direct", "group", "community"].map((t) => (
          <button
            key={t || "all"}
            onClick={() => {
              setPage(1);
              setChatType(t);
            }}
            className={`rounded-lg px-3 py-1.5 text-xs font-medium transition ${
              chatType === t
                ? "glass text-white"
                : "text-slate-400 hover:bg-white/5 hover:text-white"
            }`}
          >
            {t || "All"}
          </button>
        ))}
      </div>

      {error && (
        <p className="mt-4 rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
          {error}
        </p>
      )}

      <GlassCard className="mt-4 overflow-hidden">
        {loading ? (
          <div className="flex justify-center py-12">
            <Spinner />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-white/10 text-xs uppercase tracking-wide text-slate-400">
                  <th className="px-4 py-3 font-medium">Type</th>
                  <th className="px-4 py-3 font-medium">Participants</th>
                  <th className="px-4 py-3 font-medium">Created</th>
                  <th className="px-4 py-3 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((c) => (
                  <tr
                    key={c._id}
                    className="border-b border-white/5 last:border-0 hover:bg-white/5"
                  >
                    <td className="px-4 py-3">
                      <Badge>{c.chatType}</Badge>
                    </td>
                    <td className="px-4 py-3 text-slate-300">
                      {c.chatType === "direct"
                        ? [c.sender?.name, c.receiver?.name].filter(Boolean).join(" ↔ ") || "—"
                        : c.spaceId?.name || "Untitled group"}
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-400">
                      {new Date(c.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3 text-right space-x-2">
                      <Button
                        variant="ghost"
                        className="px-3 py-1.5 text-xs"
                        onClick={() => onOpenChat?.(c._id)}
                      >
                        Open
                      </Button>
                      <Button
                        variant="danger"
                        className="px-3 py-1.5 text-xs"
                        disabled={busyId === c._id}
                        onClick={() => setPendingDelete(c)}
                      >
                        Delete
                      </Button>
                    </td>
                  </tr>
                ))}
                {items.length === 0 && (
                  <tr>
                    <td colSpan={4} className="px-4 py-10 text-center text-slate-400">
                      No chats found.
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

      <ConfirmDialog
        open={!!pendingDelete}
        title="Delete this chat?"
        description="This permanently deletes the chat and all of its messages."
        confirmLabel="Delete"
        onConfirm={confirmDelete}
        onCancel={() => setPendingDelete(null)}
      />
    </div>
  );
}
