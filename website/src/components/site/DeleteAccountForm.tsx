"use client";

import { useState } from "react";
import { Button } from "@/components/ui/primitives";
import { DELETION_REASONS } from "@/lib/constants";

const FIELD = "glass-input rounded-2xl px-4 py-3 text-sm outline-none";
const LABEL =
  "mb-2 block text-xs font-semibold uppercase tracking-[0.12em] text-ink-muted";

type Receipt = {
  ticketId: string;
  email: string;
  softDeletedAt: string;
  scheduledHardDeleteAt: string;
  gracePeriodDays: number;
  message: string;
};

/** Posts to /api/delete-account, which soft-deletes immediately and
 *  schedules the permanent purge. The returned ticket is shown verbatim so
 *  the user has a reference to quote to support. */
export default function DeleteAccountForm() {
  const [email, setEmail] = useState("");
  const [username, setUsername] = useState("");
  const [reason, setReason] = useState(DELETION_REASONS[0]);
  const [confirmCheck, setConfirmCheck] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [receipt, setReceipt] = useState<Receipt | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setPending(true);
    setError(null);

    try {
      const res = await fetch("/api/delete-account", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, username, reason, confirmCheck }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? "We couldn't submit the request. Please try again.");
        return;
      }
      setReceipt(data as Receipt);
    } catch {
      setError("Network error — check your connection and try again.");
    } finally {
      setPending(false);
    }
  };

  if (receipt) {
    const formatDate = (iso: string) =>
      new Date(iso).toLocaleDateString(undefined, {
        year: "numeric",
        month: "long",
        day: "numeric",
      });

    return (
      <div className="glass rounded-3xl p-6 sm:p-8">
        <div className="flex items-center gap-3">
          <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-amber-400/15 text-amber-500">
            <svg
              className="h-6 w-6"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth={1.8}
              strokeLinecap="round"
              aria-hidden="true"
            >
              <circle cx="12" cy="12" r="8.5" />
              <path d="M12 8v5M12 16h.01" />
            </svg>
          </span>
          <div>
            <h3 className="text-lg font-semibold text-ink">
              Deletion request received
            </h3>
            <p className="text-sm text-ink-soft">
              Your account is deactivated immediately.
            </p>
          </div>
        </div>

        <dl className="mt-6 grid gap-px overflow-hidden rounded-2xl border border-hairline bg-hairline sm:grid-cols-2">
          {[
            ["Reference ID", receipt.ticketId],
            ["Account", receipt.email],
            ["Deactivated", formatDate(receipt.softDeletedAt)],
            ["Permanent purge", formatDate(receipt.scheduledHardDeleteAt)],
          ].map(([label, value]) => (
            <div key={label} className="bg-surface px-4 py-3">
              <dt className="text-[11px] font-semibold uppercase tracking-[0.12em] text-ink-muted">
                {label}
              </dt>
              <dd className="mt-1 break-all font-mono text-sm text-ink">{value}</dd>
            </div>
          ))}
        </dl>

        <p className="mt-5 text-sm leading-relaxed text-ink-soft">
          You have a <strong className="text-ink">{receipt.gracePeriodDays}-day</strong>{" "}
          grace period. Sign back in before the purge date to cancel the request
          and restore everything. After that date, your profile, rooms, messages
          and audio metadata are permanently erased and cannot be recovered.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="glass rounded-3xl p-6 sm:p-8">
      <h2 className="text-xl font-semibold text-ink">Request account deletion</h2>
      <p className="mt-2 text-sm text-ink-soft">
        Submit the email registered to your Talkmos account. We deactivate it
        right away and permanently purge it after the grace period.
      </p>

      <div className="mt-6 grid gap-5 sm:grid-cols-2">
        <div>
          <label className={LABEL} htmlFor="del-email">
            Account email
          </label>
          <input
            id="del-email"
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            className={FIELD}
          />
        </div>
        <div>
          <label className={LABEL} htmlFor="del-username">
            Username <span className="normal-case text-ink-faint">(optional)</span>
          </label>
          <input
            id="del-username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="@yourhandle"
            className={FIELD}
          />
        </div>
        <div className="sm:col-span-2">
          <label className={LABEL} htmlFor="del-reason">
            Reason for leaving
          </label>
          <select
            id="del-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className={`${FIELD} appearance-none`}
          >
            {DELETION_REASONS.map((r) => (
              <option key={r} value={r} className="bg-surface text-ink">
                {r}
              </option>
            ))}
          </select>
        </div>
      </div>

      <label className="mt-6 flex cursor-pointer items-start gap-3 rounded-2xl border border-hairline p-4 transition-colors hover:border-brand-primary/40">
        <input
          type="checkbox"
          checked={confirmCheck}
          onChange={(e) => setConfirmCheck(e.target.checked)}
          className="mt-0.5 h-4 w-4 shrink-0 accent-[#0266fa]"
        />
        <span className="text-sm leading-relaxed text-ink-soft">
          I understand my account will be deactivated immediately, and that all
          my data will be permanently deleted after the 30-day grace period.
        </span>
      </label>

      {error && (
        <p
          role="alert"
          className="mt-4 rounded-2xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-500 dark:text-red-300"
        >
          {error}
        </p>
      )}

      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <Button type="submit" disabled={pending || !confirmCheck} size="md">
          {pending ? "Submitting…" : "Request deletion"}
        </Button>
        <p className="text-xs text-ink-muted">
          You can cancel any time before the purge date.
        </p>
      </div>
    </form>
  );
}
