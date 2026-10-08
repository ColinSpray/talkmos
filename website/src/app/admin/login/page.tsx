"use client";

import { useEffect, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "../_lib/auth";
import { GlassCard } from "../_components/GlassCard";
import { Button } from "../_components/Button";
import { apiErrorMessage } from "../_lib/api";

export default function LoginPage() {
  const { user, loading, login } = useAuth();
  const router = useRouter();
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!loading && user) {
      router.replace("/admin/dashboard");
    }
  }, [loading, user, router]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await login(identifier, password);
      router.replace("/admin/dashboard");
    } catch (err) {
      setError(apiErrorMessage(err, "Login failed"));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center p-4">
      <GlassCard className="w-full max-w-sm p-8">
        <h1 className="text-xl font-semibold text-white">Talkmos Admin</h1>
        <p className="mt-1 text-sm text-slate-400">
          Sign in with an administrator account.
        </p>

        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-slate-300">
              Email or username
            </label>
            <input
              type="text"
              required
              autoFocus
              value={identifier}
              onChange={(e) => setIdentifier(e.target.value)}
              className="glass-input w-full rounded-xl px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500"
              placeholder="you@talkmos.com"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-medium text-slate-300">
              Password
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="glass-input w-full rounded-xl px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500"
              placeholder="••••••••"
            />
          </div>

          {error && (
            <p className="rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
              {error}
            </p>
          )}

          <Button
            type="submit"
            disabled={submitting}
            className="w-full justify-center py-2.5"
          >
            {submitting ? "Signing in…" : "Sign in"}
          </Button>
        </form>
      </GlassCard>
    </div>
  );
}
