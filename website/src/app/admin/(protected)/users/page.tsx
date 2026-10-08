"use client";

import { useCallback, useEffect, useState } from "react";
import { api, apiErrorMessage } from "@/app/admin/_lib/api";
import { GlassCard } from "@/app/admin/_components/GlassCard";
import { Badge } from "@/app/admin/_components/Badge";
import { Spinner } from "@/app/admin/_components/Spinner";
import { Pagination } from "@/app/admin/_components/Pagination";
import { ConfirmDialog } from "@/app/admin/_components/ConfirmDialog";
import { Button } from "@/app/admin/_components/Button";
import type { AdminUser, Pagination as PaginationInfo } from "@/app/admin/_lib/types";

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [pagination, setPagination] = useState<PaginationInfo | null>(null);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [searchInput, setSearchInput] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pendingDelete, setPendingDelete] = useState<AdminUser | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    api
      .get("/admin/users", { params: { page, limit: 20, search: search || undefined } })
      .then(({ data }) => {
        setUsers(data.data);
        setPagination(data.pagination);
      })
      .catch((err) => setError(apiErrorMessage(err, "Failed to load users")))
      .finally(() => setLoading(false));
  }, [page, search]);

  useEffect(load, [load]);

  function submitSearch(e: React.FormEvent) {
    e.preventDefault();
    setPage(1);
    setSearch(searchInput.trim());
  }

  async function updateUser(id: string, patch: Partial<AdminUser>) {
    setBusyId(id);
    try {
      const { data } = await api.patch(`/admin/users/${id}`, patch);
      setUsers((prev) => prev.map((u) => (u._id === id ? data.data : u)));
    } catch (err) {
      setError(apiErrorMessage(err, "Failed to update user"));
    } finally {
      setBusyId(null);
    }
  }

  async function confirmDelete() {
    if (!pendingDelete) return;
    const id = pendingDelete._id;
    setBusyId(id);
    try {
      await api.delete(`/admin/users/${id}`);
      setUsers((prev) => prev.filter((u) => u._id !== id));
    } catch (err) {
      setError(apiErrorMessage(err, "Failed to delete user"));
    } finally {
      setBusyId(null);
      setPendingDelete(null);
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-white">Users</h1>
      <p className="mt-1 text-sm text-slate-400">
        Search, verify, promote, or remove accounts.
      </p>

      <form onSubmit={submitSearch} className="mt-6 flex gap-3">
        <input
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          placeholder="Search by name, email, phone, username…"
          className="glass-input w-full max-w-sm rounded-xl px-3.5 py-2 text-sm text-white placeholder:text-slate-500"
        />
        <Button type="submit" variant="ghost">
          Search
        </Button>
      </form>

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
                  <th className="px-4 py-3 font-medium">User</th>
                  <th className="px-4 py-3 font-medium">Contact</th>
                  <th className="px-4 py-3 font-medium">Role</th>
                  <th className="px-4 py-3 font-medium">Premium</th>
                  <th className="px-4 py-3 font-medium">Verified</th>
                  <th className="px-4 py-3 font-medium">Joined</th>
                  <th className="px-4 py-3 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr
                    key={u._id}
                    className="border-b border-white/5 last:border-0 hover:bg-white/5"
                  >
                    <td className="px-4 py-3">
                      <p className="font-medium text-white">{u.name || "—"}</p>
                      <p className="text-xs text-slate-400">
                        @{u.username || "no-username"}
                      </p>
                    </td>
                    <td className="px-4 py-3 text-slate-300">
                      <p>{u.email || "—"}</p>
                      <p className="text-xs text-slate-400">{u.phone || ""}</p>
                    </td>
                    <td className="px-4 py-3">
                      <select
                        value={u.role}
                        disabled={busyId === u._id}
                        onChange={(e) =>
                          updateUser(u._id, {
                            role: e.target.value as AdminUser["role"],
                          })
                        }
                        className="glass-input rounded-lg px-2 py-1 text-xs text-white"
                      >
                        <option value="user">user</option>
                        <option value="admin">admin</option>
                      </select>
                    </td>
                    <td className="px-4 py-3">
                      <button
                        disabled={busyId === u._id}
                        onClick={() =>
                          updateUser(u._id, { isPremium: !u.isPremium })
                        }
                      >
                        <Badge tone={u.isPremium ? "success" : "neutral"}>
                          {u.isPremium ? "Premium" : "Free"}
                        </Badge>
                      </button>
                    </td>
                    <td className="px-4 py-3">
                      <button
                        disabled={busyId === u._id}
                        onClick={() =>
                          updateUser(u._id, { isVerified: !u.isVerified })
                        }
                      >
                        <Badge tone={u.isVerified ? "info" : "neutral"}>
                          {u.isVerified ? "Verified" : "Unverified"}
                        </Badge>
                      </button>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-400">
                      {u.createdAt
                        ? new Date(u.createdAt).toLocaleDateString()
                        : "—"}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Button
                        variant="danger"
                        className="px-3 py-1.5 text-xs"
                        disabled={busyId === u._id}
                        onClick={() => setPendingDelete(u)}
                      >
                        Delete
                      </Button>
                    </td>
                  </tr>
                ))}
                {users.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-4 py-10 text-center text-slate-400">
                      No users found.
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
        title="Delete this user?"
        description={`This permanently deletes ${pendingDelete?.name || pendingDelete?.email || "this account"}. This cannot be undone.`}
        confirmLabel="Delete"
        onConfirm={confirmDelete}
        onCancel={() => setPendingDelete(null)}
      />
    </div>
  );
}
