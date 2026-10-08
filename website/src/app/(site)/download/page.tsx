import type { Metadata } from "next";
import Link from "next/link";
import Icon from "@/components/Icon";
import Reveal from "@/components/ui/Reveal";
import PhoneMockup from "@/components/site/PhoneMockup";
import PlayStoreButton from "@/components/site/PlayStoreButton";
import ApkDownloadButton from "@/components/site/ApkDownloadButton";
import {
  Container,
  Eyebrow,
  GlassCard,
  Section,
  SectionHeading,
} from "@/components/ui/primitives";
import { APP_CONFIG, STEPS } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Download",
  description:
    "Download Talkmos free on Google Play, or grab the APK directly. Android 8.0 and up, no subscription required.",
  alternates: { canonical: "/download" },
};

const REQUIREMENTS = [
  { label: "Platform", value: "Android 8.0 (API 26) and up" },
  { label: "Download size", value: `≈ ${APP_CONFIG.apkSize}` },
  { label: "Package", value: APP_CONFIG.packageName },
  { label: "Current version", value: `v${APP_CONFIG.appVersion}` },
  { label: "Price", value: "Free — no subscription" },
  { label: "Updated", value: APP_CONFIG.lastUpdated },
];

const SIDELOAD_STEPS = [
  {
    title: "Download the file",
    detail: "Your browser will warn that .apk files can be harmful — that prompt appears for every APK, not just ours. Keep the file.",
  },
  {
    title: "Allow installs from your browser",
    detail: "Android asks once, per app. Settings → Apps → Special access → Install unknown apps → your browser → Allow.",
  },
  {
    title: "Open it and install",
    detail: "Tap the downloaded file. Play Protect scans it, then the standard installer takes over.",
  },
];

const PERMISSIONS = [
  {
    icon: "microphone" as const,
    name: "Microphone (RECORD_AUDIO)",
    why: "Required to capture your voice while you are transmitting. Access is scoped to an active session — Talkmos never listens in the background.",
  },
  {
    icon: "globe" as const,
    name: "Internet & network state",
    why: "Used to connect to voice relays and to detect when you move between Wi-Fi and mobile data so the session can survive the handover.",
  },
  {
    icon: "bell" as const,
    name: "Notifications (optional)",
    why: "Lets you know when someone starts talking in a room you follow. Decline it and the app still works, just quietly.",
  },
  {
    icon: "battery" as const,
    name: "Bluetooth (optional)",
    why: "Routes audio to wireless headsets and car systems, and enables headset media buttons as a push-to-talk trigger.",
  },
];

export default function DownloadPage() {
  return (
    <>
      <section className="pb-10 pt-14 sm:pt-20">
        <Container size="wide">
          <div className="grid items-center gap-14 lg:grid-cols-2 lg:gap-12">
            <Reveal>
              <div className="flex flex-col items-start gap-5">
                <Eyebrow dot>v{APP_CONFIG.appVersion} · live on Google Play</Eyebrow>
                <h1 className="text-4xl font-bold tracking-tight text-ink sm:text-5xl lg:text-6xl">
                  Get <span className="brand-gradient-text">Talkmos</span> for
                  Android
                </h1>
                <p className="max-w-xl text-lg leading-relaxed text-ink-soft">
                  Free, with no account wall before you can hear how it sounds.
                  Install it from Google Play, or download the APK directly if
                  your device has no Play Store.
                </p>
                <div className="mt-3 flex flex-col gap-3 sm:flex-row sm:items-center">
                  <PlayStoreButton size="lg" />
                  <ApkDownloadButton size="lg" />
                </div>
                <p className="text-xs text-ink-muted">
                  Play Store listing, or a {APP_CONFIG.apkSize} .apk file.
                </p>
              </div>
            </Reveal>

            <Reveal delay={140}>
              <PhoneMockup />
            </Reveal>
          </div>
        </Container>
      </section>

      {/* Requirements */}
      <Section className="pt-10">
        <Container>
          <Reveal>
            <SectionHeading
              eyebrow="Before you install"
              title="Requirements & release details"
            />
          </Reveal>
          <Reveal delay={100}>
            <GlassCard interactive={false} className="mt-12 overflow-hidden p-0">
              <dl className="grid gap-px bg-hairline sm:grid-cols-2 lg:grid-cols-3">
                {REQUIREMENTS.map((req) => (
                  <div key={req.label} className="bg-surface/70 px-6 py-5 backdrop-blur-xl">
                    <dt className="text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-muted">
                      {req.label}
                    </dt>
                    <dd className="mt-2 break-words text-sm font-medium text-ink">
                      {req.value}
                    </dd>
                  </div>
                ))}
              </dl>
            </GlassCard>
          </Reveal>
        </Container>
      </Section>

      {/* Direct APK */}
      <Section className="pt-0">
        <Container>
          <Reveal>
            <GlassCard interactive={false} className="glass-outline relative overflow-hidden p-7 sm:p-10">
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -right-16 -top-16 h-52 w-52 rounded-full bg-brand-primary/20 blur-3xl"
              />
              <div className="relative grid gap-8 lg:grid-cols-2 lg:items-center lg:gap-12">
                <div>
                  <Eyebrow>No Play Store?</Eyebrow>
                  <h2 className="mt-5 text-2xl font-bold tracking-tight text-ink sm:text-3xl">
                    Install the APK directly
                  </h2>
                  <p className="mt-4 text-sm leading-relaxed text-ink-soft sm:text-base">
                    The same build, served straight from our servers as a
                    signed {APP_CONFIG.apkSize} package. Useful for testers, for
                    devices without Google Play services, and for anyone who
                    would rather not wait on a staged rollout.
                  </p>
                  <div className="mt-7">
                    <ApkDownloadButton size="lg" variant="primary" />
                  </div>
                </div>

                <ol className="flex flex-col gap-4">
                  {SIDELOAD_STEPS.map((step, i) => (
                    <li key={step.title} className="flex gap-4">
                      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-brand-primary/12 font-mono text-xs font-bold text-link">
                        {i + 1}
                      </span>
                      <span>
                        <span className="block text-sm font-semibold text-ink">
                          {step.title}
                        </span>
                        <span className="mt-1 block text-sm leading-relaxed text-ink-soft">
                          {step.detail}
                        </span>
                      </span>
                    </li>
                  ))}
                </ol>
              </div>
            </GlassCard>
          </Reveal>
        </Container>
      </Section>

      {/* Permissions */}
      <Section className="pt-0">
        <Container>
          <Reveal>
            <SectionHeading
              eyebrow="Transparency"
              title="Every permission, and why"
              description="Talkmos asks for as little as it can get away with, and explains each request in the app at the moment it needs it."
            />
          </Reveal>
          <div className="mt-14 grid gap-5 sm:grid-cols-2">
            {PERMISSIONS.map((perm, i) => (
              <Reveal key={perm.name} delay={i * 70}>
                <GlassCard className="flex h-full items-start gap-4 p-6">
                  <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-brand-primary/12 text-link">
                    <Icon name={perm.icon} className="h-5 w-5" />
                  </span>
                  <div>
                    <h3 className="text-base font-semibold text-ink">
                      {perm.name}
                    </h3>
                    <p className="mt-2 text-sm leading-relaxed text-ink-soft">
                      {perm.why}
                    </p>
                  </div>
                </GlassCard>
              </Reveal>
            ))}
          </div>
          <Reveal delay={120}>
            <p className="mt-8 text-center text-sm text-ink-muted">
              Full detail lives in the{" "}
              <Link
                href="/privacy"
                className="font-medium text-link underline-offset-4 hover:underline"
              >
                Privacy Policy
              </Link>
              .
            </p>
          </Reveal>
        </Container>
      </Section>

      {/* Setup steps */}
      <Section className="pt-0 pb-24">
        <Container>
          <Reveal>
            <SectionHeading eyebrow="After installing" title="Your first minute" />
          </Reveal>
          <ol className="mt-14 grid gap-5 lg:grid-cols-3">
            {STEPS.map((step, i) => (
              <Reveal key={step.step} delay={i * 90} as="li">
                <GlassCard className="h-full p-7">
                  <span className="brand-gradient inline-flex h-11 w-11 items-center justify-center rounded-2xl font-mono text-sm font-bold text-white">
                    {step.step}
                  </span>
                  <h3 className="mt-5 text-lg font-semibold text-ink">
                    {step.title}
                  </h3>
                  <p className="mt-2.5 text-sm leading-relaxed text-ink-soft">
                    {step.description}
                  </p>
                </GlassCard>
              </Reveal>
            ))}
          </ol>
        </Container>
      </Section>
    </>
  );
}
