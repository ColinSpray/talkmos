"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Image from "next/image";
import { api, apiErrorMessage } from "@/app/admin/_lib/api";
import { GlassCard } from "@/app/admin/_components/GlassCard";
import { Button } from "@/app/admin/_components/Button";
import { Spinner } from "@/app/admin/_components/Spinner";
import { ConfirmDialog } from "@/app/admin/_components/ConfirmDialog";
import type { AdminUser } from "@/app/admin/_lib/types";

type Target = "all" | "premium" | "verified" | "unverified" | "user";

const TARGETS: { key: Target; label: string; description: string }[] = [
  { key: "all", label: "All Users", description: "Every registered user." },
  { key: "premium", label: "Premium", description: "Users with an active premium subscription." },
  { key: "verified", label: "Verified", description: "Users with a verified account." },
  { key: "unverified", label: "Unverified", description: "Users who haven't verified yet." },
  { key: "user", label: "Specific User", description: "Send to one user you pick below." },
];

interface BroadcastResult {
  recipients: number;
  pushed: number;
  failed: number;
}

export default function NotificationsPage() {
  const [target, setTarget] = useState<Target>("all");
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [userQuery, setUserQuery] = useState("");
  const [userResults, setUserResults] = useState<AdminUser[]>([]);
  const [searchingUsers, setSearchingUsers] = useState(false);

  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");

  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [imageError, setImageError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [sending, setSending] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<BroadcastResult | null>(null);

  // Debounced user lookup for the "Specific User" target.
  useEffect(() => {
    if (target !== "user" || selectedUser || !userQuery.trim()) {
      setUserResults([]);
      return;
    }
    setSearchingUsers(true);
    const handle = setTimeout(() => {
      api
        .get("/admin/users", { params: { search: userQuery.trim(), limit: 8 } })
        .then(({ data }) => setUserResults(data.data))
        .catch(() => setUserResults([]))
        .finally(() => setSearchingUsers(false));
    }, 300);
    return () => clearTimeout(handle);
  }, [userQuery, target, selectedUser]);

  const handleFileChange = useCallback(async (file: File | null) => {
    setImageError(null);
    setImageUrl(null);
    if (!file) {
      setImagePreview(null);
      return;
    }

    setImagePreview(URL.createObjectURL(file));
    setUploadingImage(true);
    try {
      const { data } = await api.post("/chat/media/upload", {
        fileName: file.name,
        mimeType: file.type,
      });

      const form = new FormData();
      Object.entries(data.fields || {}).forEach(([key, value]) => {
        form.append(key, String(value));
      });
      form.append("file", file);

      // Direct upload to the storage provider — never through the `api`
      // instance, which would attach our admin bearer token to a
      // third-party host.
      const uploadRes = await fetch(data.uploadUrl, { method: data.method || "POST", body: form });
      if (!uploadRes.ok) throw new Error("Upload failed");

      setImageUrl(data.mediaUrl);
    } catch (err) {
      setImageError(apiErrorMessage(err, "Failed to upload image"));
      setImagePreview(null);
    } finally {
      setUploadingImage(false);
    }
  }, []);

  function removeImage() {
    setImagePreview(null);
    setImageUrl(null);
    setImageError(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  function resetMessage() {
    setTitle("");
    setBody("");
    removeImage();
  }

  const canSend =
    title.trim().length > 0 &&
    body.trim().length > 0 &&
    !uploadingImage &&
    (target !== "user" || !!selectedUser);

  async function send() {
    setSending(true);
    setError(null);
    setResult(null);
    try {
      const { data } = await api.post("/admin/notifications/broadcast", {
        target,
        userId: target === "user" ? selectedUser?._id : undefined,
        title: title.trim(),
        body: body.trim(),
        imageUrl: imageUrl || undefined,
      });
      setResult(data.data);
      resetMessage();
    } catch (err) {
      setError(apiErrorMessage(err, "Failed to send broadcast"));
    } finally {
      setSending(false);
    }
  }

  function handleSendClick() {
    if (!canSend) return;
    if (target === "all") {
      setConfirmOpen(true);
      return;
    }
    send();
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-white">Notification Broadcaster</h1>
      <p className="mt-1 text-sm text-slate-400">
        Push a system notification to a filtered group of users, or a single account.
      </p>

      {error && (
        <p className="mt-4 rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
          {error}
        </p>
      )}

      {result && (
        <p className="mt-4 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-sm text-emerald-300">
          Sent to {result.recipients} recipient{result.recipients === 1 ? "" : "s"} — {result.pushed} push
          {result.pushed === 1 ? "" : "es"} delivered, {result.failed} failed.
        </p>
      )}

      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-12">
        {/* Composer */}
        <GlassCard className="p-6 lg:col-span-7 space-y-6">
          <div>
            <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              Audience
            </p>
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {TARGETS.map((t) => (
                <button
                  key={t.key}
                  type="button"
                  onClick={() => {
                    setTarget(t.key);
                    setSelectedUser(null);
                    setUserQuery("");
                  }}
                  title={t.description}
                  className={`rounded-xl px-3 py-2 text-left text-xs font-medium transition ${
                    target === t.key
                      ? "glass text-white"
                      : "bg-white/5 text-slate-400 hover:bg-white/10 hover:text-white"
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            {target === "user" && (
              <div className="relative mt-3">
                {selectedUser ? (
                  <div className="glass-input flex items-center justify-between rounded-xl px-3.5 py-2">
                    <div>
                      <p className="text-sm font-medium text-white">
                        {selectedUser.name || selectedUser.username || "Unnamed user"}
                      </p>
                      <p className="text-xs text-slate-400">
                        {selectedUser.email || selectedUser.phone}
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setSelectedUser(null)}
                      className="text-xs font-medium text-slate-400 hover:text-white"
                    >
                      Change
                    </button>
                  </div>
                ) : (
                  <>
                    <input
                      value={userQuery}
                      onChange={(e) => setUserQuery(e.target.value)}
                      placeholder="Search by name, email, phone, username…"
                      className="glass-input w-full rounded-xl px-3.5 py-2 text-sm text-white placeholder:text-slate-500"
                    />
                    {(searchingUsers || userResults.length > 0) && userQuery.trim() && (
                      <div className="glass-panel absolute z-10 mt-1 w-full overflow-hidden rounded-xl">
                        {searchingUsers ? (
                          <div className="flex justify-center py-3">
                            <Spinner />
                          </div>
                        ) : (
                          userResults.map((u) => (
                            <button
                              key={u._id}
                              type="button"
                              onClick={() => {
                                setSelectedUser(u);
                                setUserResults([]);
                              }}
                              className="block w-full px-3.5 py-2 text-left text-sm text-slate-200 hover:bg-white/10"
                            >
                              <span className="font-medium text-white">
                                {u.name || u.username || "Unnamed user"}
                              </span>{" "}
                              <span className="text-xs text-slate-400">
                                {u.email || u.phone}
                              </span>
                            </button>
                          ))
                        )}
                      </div>
                    )}
                  </>
                )}
              </div>
            )}
          </div>

          <div>
            <label className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-400">
              Title
            </label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              maxLength={120}
              placeholder="e.g. New feature: Spatial Audio Rooms"
              className="glass-input w-full rounded-xl px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500"
            />
          </div>

          <div>
            <label className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-400">
              Content
            </label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              rows={4}
              maxLength={500}
              placeholder="What do you want to tell your users?"
              className="glass-input w-full rounded-xl px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500"
            />
            <p className="mt-1 text-right text-xs text-slate-500">{body.length}/500</p>
          </div>

          <div>
            <label className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-400">
              Image (optional)
            </label>
            {imagePreview ? (
              <div className="relative w-fit">
                <Image
                  src={imagePreview}
                  alt="Notification image preview"
                  width={160}
                  height={160}
                  unoptimized
                  className="h-28 w-28 rounded-xl object-cover"
                />
                {uploadingImage && (
                  <div className="absolute inset-0 flex items-center justify-center rounded-xl bg-black/50">
                    <Spinner />
                  </div>
                )}
                {!uploadingImage && (
                  <button
                    type="button"
                    onClick={removeImage}
                    className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-rose-500 text-xs text-white shadow-md hover:bg-rose-400"
                    aria-label="Remove image"
                  >
                    ✕
                  </button>
                )}
              </div>
            ) : (
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="glass-input flex h-28 w-28 flex-col items-center justify-center gap-1 rounded-xl text-xs text-slate-400 hover:text-white"
              >
                <span className="text-lg">＋</span>
                Add image
              </button>
            )}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => handleFileChange(e.target.files?.[0] ?? null)}
            />
            {imageError && <p className="mt-2 text-xs text-rose-300">{imageError}</p>}
          </div>

          <Button
            onClick={handleSendClick}
            disabled={!canSend || sending}
            className="w-full justify-center py-3"
          >
            {sending ? <Spinner /> : "Send Broadcast"}
          </Button>
        </GlassCard>

        {/* Live preview */}
        <div className="lg:col-span-5">
          <GlassCard className="p-6">
            <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-slate-400">
              Preview
            </p>
            <div className="glass-panel flex gap-3 rounded-2xl p-3">
              <div className="h-10 w-10 shrink-0 overflow-hidden rounded-lg bg-white/10">
                <Image src="/logo.png" alt="Talkmos" width={40} height={40} className="h-full w-full object-cover" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-white">
                  {title.trim() || "Notification title"}
                </p>
                <p className="mt-0.5 line-clamp-3 text-xs text-slate-300">
                  {body.trim() || "Your message content will appear here."}
                </p>
                {imagePreview && (
                  <Image
                    src={imagePreview}
                    alt=""
                    width={400}
                    height={160}
                    unoptimized
                    className="mt-2 h-24 w-full rounded-lg object-cover"
                  />
                )}
              </div>
            </div>
            <p className="mt-4 text-xs text-slate-500">
              Audience: <span className="text-slate-300">{TARGETS.find((t) => t.key === target)?.label}</span>
              {target === "user" && selectedUser && (
                <> — {selectedUser.name || selectedUser.email || selectedUser.phone}</>
              )}
            </p>
          </GlassCard>
        </div>
      </div>

      <ConfirmDialog
        open={confirmOpen}
        title="Send to all users?"
        description="This pushes a notification to every registered user right now. This can't be undone."
        confirmLabel="Send to Everyone"
        onConfirm={() => {
          setConfirmOpen(false);
          send();
        }}
        onCancel={() => setConfirmOpen(false)}
      />
    </div>
  );
}
