"use client";

import { useEffect, useState, type FormEvent } from "react";
import { api, apiErrorMessage } from "@/app/admin/_lib/api";
import { GlassCard } from "@/app/admin/_components/GlassCard";
import { Button } from "@/app/admin/_components/Button";
import { Spinner } from "@/app/admin/_components/Spinner";
import type { SystemSettings } from "@/app/admin/_lib/types";

function Toggle({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label className="flex items-center justify-between gap-4 py-2">
      <span className="text-sm text-slate-200">{label}</span>
      <button
        type="button"
        onClick={() => onChange(!checked)}
        className={`relative h-6 w-11 shrink-0 rounded-full border transition ${
          checked
            ? "border-brand-primary-light/50 bg-brand-primary/70"
            : "border-white/15 bg-white/10"
        }`}
      >
        <span
          className={`absolute top-0.5 h-4.5 w-4.5 rounded-full bg-white shadow transition ${
            checked ? "left-5.5" : "left-0.5"
          }`}
        />
      </button>
    </label>
  );
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<SystemSettings | null>(null);
  const [domainsInput, setDomainsInput] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [apkFile, setApkFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);

  useEffect(() => {
    api
      .get("/admin/settings")
      .then(({ data }) => {
        setSettings(data.data);
        setDomainsInput((data.data.allowedEmailDomains ?? []).join(", "));
      })
      .catch((err) => setError(apiErrorMessage(err, "Failed to load settings")))
      .finally(() => setLoading(false));
  }, []);

  async function handleSave(e: FormEvent) {
    e.preventDefault();
    if (!settings) return;
    setSaving(true);
    setError(null);
    setSuccess(null);
    try {
      const { data } = await api.patch("/admin/settings", {
        allowNewRegistrations: settings.allowNewRegistrations,
        maintenanceMode: settings.maintenanceMode,
        allowedEmailDomains: domainsInput
          .split(",")
          .map((d) => d.trim())
          .filter(Boolean),
        latestVersionName: settings.latestVersionName,
        latestVersionCode: settings.latestVersionCode,
        minRequiredVersionCode: settings.minRequiredVersionCode,
        releaseNotes: settings.releaseNotes,
        isForceUpdate: settings.isForceUpdate,
      });
      setSettings(data.data);
      setSuccess("Settings saved.");
    } catch (err) {
      setError(apiErrorMessage(err, "Failed to save settings"));
    } finally {
      setSaving(false);
    }
  }

  async function handleUpload(e: FormEvent) {
    e.preventDefault();
    if (!apkFile || !settings) return;
    setUploading(true);
    setUploadError(null);
    setUploadSuccess(null);
    try {
      const form = new FormData();
      form.append("apk", apkFile);
      form.append("versionName", settings.latestVersionName);
      form.append("versionCode", String(settings.latestVersionCode));
      form.append("minRequiredVersionCode", String(settings.minRequiredVersionCode));
      form.append("releaseNotes", settings.releaseNotes);
      form.append("isForceUpdate", String(settings.isForceUpdate));

      await api.post("/apk/upload", form, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      setUploadSuccess("APK uploaded and published.");
      setApkFile(null);
    } catch (err) {
      setUploadError(apiErrorMessage(err, "Failed to upload APK"));
    } finally {
      setUploading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <Spinner />
      </div>
    );
  }

  if (!settings) {
    return (
      <p className="rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
        {error}
      </p>
    );
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold text-white">Settings &amp; Releases</h1>
      <p className="mt-1 text-sm text-slate-400">
        Control platform-wide behavior and manage the Android release.
      </p>

      <form onSubmit={handleSave} className="mt-6 grid gap-6 lg:grid-cols-2">
        <GlassCard className="p-6">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-300">
            Access
          </h2>
          <div className="mt-3 divide-y divide-white/5">
            <Toggle
              label="Allow new registrations"
              checked={settings.allowNewRegistrations}
              onChange={(v) => setSettings({ ...settings, allowNewRegistrations: v })}
            />
            <Toggle
              label="Maintenance mode"
              checked={settings.maintenanceMode}
              onChange={(v) => setSettings({ ...settings, maintenanceMode: v })}
            />
          </div>
          <div className="mt-4">
            <label className="mb-1.5 block text-xs font-medium text-slate-300">
              Allowed email domains (comma-separated, empty = any)
            </label>
            <input
              value={domainsInput}
              onChange={(e) => setDomainsInput(e.target.value)}
              placeholder="talkmos.com, example.org"
              className="glass-input w-full rounded-xl px-3.5 py-2 text-sm text-white placeholder:text-slate-500"
            />
          </div>
        </GlassCard>

        <GlassCard className="p-6">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-300">
            Release info
          </h2>
          <div className="mt-3 grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1.5 block text-xs font-medium text-slate-300">
                Version name
              </label>
              <input
                value={settings.latestVersionName}
                onChange={(e) =>
                  setSettings({ ...settings, latestVersionName: e.target.value })
                }
                className="glass-input w-full rounded-xl px-3.5 py-2 text-sm text-white"
              />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-medium text-slate-300">
                Version code
              </label>
              <input
                type="number"
                value={settings.latestVersionCode}
                onChange={(e) =>
                  setSettings({ ...settings, latestVersionCode: Number(e.target.value) })
                }
                className="glass-input w-full rounded-xl px-3.5 py-2 text-sm text-white"
              />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-medium text-slate-300">
                Min required version code
              </label>
              <input
                type="number"
                value={settings.minRequiredVersionCode}
                onChange={(e) =>
                  setSettings({
                    ...settings,
                    minRequiredVersionCode: Number(e.target.value),
                  })
                }
                className="glass-input w-full rounded-xl px-3.5 py-2 text-sm text-white"
              />
            </div>
            <div className="flex items-end">
              <Toggle
                label="Force update"
                checked={settings.isForceUpdate}
                onChange={(v) => setSettings({ ...settings, isForceUpdate: v })}
              />
            </div>
          </div>
          <div className="mt-3">
            <label className="mb-1.5 block text-xs font-medium text-slate-300">
              Release notes
            </label>
            <textarea
              value={settings.releaseNotes}
              onChange={(e) => setSettings({ ...settings, releaseNotes: e.target.value })}
              rows={3}
              className="glass-input w-full rounded-xl px-3.5 py-2 text-sm text-white"
            />
          </div>
        </GlassCard>

        <div className="lg:col-span-2">
          {error && (
            <p className="mb-4 rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
              {error}
            </p>
          )}
          {success && (
            <p className="mb-4 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-sm text-emerald-300">
              {success}
            </p>
          )}
          <Button type="submit" disabled={saving}>
            {saving ? "Saving…" : "Save settings"}
          </Button>
        </div>
      </form>

      <GlassCard className="mt-6 p-6">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-300">
          Publish APK
        </h2>
        <p className="mt-1 text-xs text-slate-400">
          Uploads the binary and applies the release info above in one step.
        </p>
        <form onSubmit={handleUpload} className="mt-4 flex flex-wrap items-center gap-3">
          <input
            type="file"
            accept=".apk"
            onChange={(e) => setApkFile(e.target.files?.[0] ?? null)}
            className="text-sm text-slate-300 file:mr-3 file:rounded-lg file:border-0 file:bg-white/10 file:px-3 file:py-1.5 file:text-sm file:text-white"
          />
          <Button type="submit" variant="ghost" disabled={!apkFile || uploading}>
            {uploading ? "Uploading…" : "Upload & publish"}
          </Button>
        </form>
        {uploadError && (
          <p className="mt-3 rounded-lg border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-300">
            {uploadError}
          </p>
        )}
        {uploadSuccess && (
          <p className="mt-3 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-sm text-emerald-300">
            {uploadSuccess}
          </p>
        )}
      </GlassCard>
    </div>
  );
}
