"use client";

import { useCallback, useEffect, useState } from "react";
import { api, apiErrorMessage } from "@/app/admin/_lib/api";
import { GlassCard } from "@/app/admin/_components/GlassCard";
import { Spinner } from "@/app/admin/_components/Spinner";
import { Pagination } from "@/app/admin/_components/Pagination";
import { ConfirmDialog } from "@/app/admin/_components/ConfirmDialog";
import { Button } from "@/app/admin/_components/Button";
import { Badge } from "@/app/admin/_components/Badge";
import type { AdminMessage, Pagination as PaginationInfo } from "@/app/admin/_lib/types";

export function MessagesTab({ initialChatId }: { initialChatId?: string } = {}) {
  const [items, setItems] = useState<AdminMessage[]>([]);
  const [pagination, setPagination] = useState<PaginationInfo | null>(null);
  const [page, setPage] = useState(1);
  const [chatId, setChatId] = useState(initialChatId ?? "");
  const [chatIdFilter, setChatIdFilter] = useState(initialChatId ?? "");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pendingDelete, setPendingDelete] = useState<AdminMessage | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    api
      .get("/admin/messages", {
        params: { page, limit: 50, chatId: chatIdFilter || undefined },
      })
      .then(({ data }) => {
        setItems(data.data);
        setPagination(data.pagination);
      })
      .catch((err) => setError(apiErrorMessage(err, "Failed to load messages")))
      .finally(() => setLoading(false));
  }, [page, chatIdFilter]);

  useEffect(load, [load]);

  async function confirmDelete() {
    if (!pendingDelete) return;
    const id = pendingDelete._id;
    setBusyId(id);
    try {
      await api.delete(`/admin/messages/${id}`);
      setItems((prev) => prev.filter((m) => m._id !== id));
    } catch (err) {
      setError(apiErrorMessage(err, "Failed to delete message"));
    } finally {
      setBusyId(null);
      setPendingDelete(null);
    }
  }

  return (
    <div>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          setPage(1);
          setChatIdFilter(chatId.trim());
        }}
        className="flex gap-3"
      >
        <input
          value={chatId}
          onChange={(e) => setChatId(e.target.value)}
          placeholder="Filter by chat ID…"
          className="glass-input w-full max-w-sm rounded-xl px-3.5 py-2 text-sm text-white placeholder:text-slate-500"
        />
        <Button type="submit" variant="ghost">
          Filter
        </Button>
        {chatIdFilter && (
          <Button
            type="button"
            variant="ghost"
            onClick={() => {
              setChatId("");
              setChatIdFilter("");
              setPage(1);
            }}
          >
            Clear
          </Button>
        )}
      </form>
      {chatIdFilter && (
        <p className="mt-2 text-xs text-slate-400">
          Showing messages for chat <span className="font-mono text-slate-300">{chatIdFilter}</span>
        </p>
      )}

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
                  <th className="px-4 py-3 font-medium">Sender</th>
                  <th className="px-4 py-3 font-medium">Type</th>
                  <th className="px-4 py-3 font-medium">Content</th>
                  <th className="px-4 py-3 font-medium">Sent</th>
                  <th className="px-4 py-3 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((m) => (
                  <tr
                    key={m._id}
                    className="border-b border-white/5 last:border-0 hover:bg-white/5"
                  >
                    <td className="px-4 py-3">
                      <p className="font-medium text-white">
                        {m.senderId?.name || "—"}
                      </p>
                      <p className="text-xs text-slate-400">
                        {m.senderId?.email || m.senderId?.phone || ""}
                      </p>
                    </td>
                    <td className="px-4 py-3">
                      <Badge>{m.messageType}</Badge>
                    </td>
                    <td className="max-w-xs truncate px-4 py-3 text-slate-300">
                      {m.messageType === "text" ? m.content : `[${m.messageType}]`}
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-400">
                      {new Date(m.createdAt).toLocaleString()}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Button
                        variant="danger"
                        className="px-3 py-1.5 text-xs"
                        disabled={busyId === m._id}
                        onClick={() => setPendingDelete(m)}
                      >
                        Delete
                      </Button>
                    </td>
                  </tr>
                ))}
                {items.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-4 py-10 text-center text-slate-400">
                      No messages found.
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
        title="Delete this message?"
        description="This permanently removes the message for everyone."
        confirmLabel="Delete"
        onConfirm={confirmDelete}
        onCancel={() => setPendingDelete(null)}
      />
    </div>
  );
}
