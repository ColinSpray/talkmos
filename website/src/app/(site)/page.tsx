import Link from "next/link";
import Icon from "@/components/Icon";
import Reveal from "@/components/ui/Reveal";
import Accordion from "@/components/ui/Accordion";
import PhoneMockup from "@/components/site/PhoneMockup";
import PlayStoreButton from "@/components/site/PlayStoreButton";
import ApkDownloadButton from "@/components/site/ApkDownloadButton";
import Waveform from "@/components/site/Waveform";
import CtaBand from "@/components/site/CtaBand";
import {
  ButtonLink,
  Container,
  Eyebrow,
  GlassCard,
  Section,
  SectionHeading,
} from "@/components/ui/primitives";
import {
  APP_CONFIG,
  FAQS,
  FEATURES,
  LATENCY_COMPARISON,
  STATS,
  STEPS,
} from "@/lib/constants";

export default function HomePage() {
  const slowest = Math.max(...LATENCY_COMPARISON.map((l) => l.ms));

  return (
    <>
      {/* ── HERO ─────────────────────────────────────────────────────── */}
      <section className="relative pb-16 pt-12 sm:pt-16 lg:pb-24 lg:pt-20">
        <Container size="wide">
          <div className="grid items-center gap-14 lg:grid-cols-12 lg:gap-10">
            <div className="flex flex-col items-center text-center lg:col-span-7 lg:items-start lg:text-left">
              <Reveal>
                <Eyebrow dot>
                  v{APP_CONFIG.appVersion} is live on Google Play
                </Eyebrow>
              </Reveal>

              <Reveal delay={80}>
                <h1 className="mt-6 text-4xl font-bold leading-[1.08] tracking-tight text-ink sm:text-6xl lg:text-[4.1rem]">
                  Voice chat built for{" "}
                  <span className="brand-gradient-text">instant connection</span>
                </h1>
              </Reveal>

              <Reveal delay={160}>
                <p className="mt-6 max-w-xl text-lg leading-relaxed text-ink-soft">
                  Talkmos gives your group ultra-low-latency audio rooms,
                  push-to-talk that fires the moment you press it, and neural
                  noise cancellation that keeps the world out of the channel.
                </p>
              </Reveal>

              <Reveal delay={240}>
                <div className="mt-9 flex flex-col items-center gap-3 sm:flex-row lg:items-start">
                  <PlayStoreButton size="lg" />
                  <ApkDownloadButton size="lg" />
                </div>
                <div className="mt-4 flex flex-col items-center gap-x-4 gap-y-2 sm:flex-row lg:items-start">
                  <Link
                    href="/technology"
                    className="inline-flex items-center gap-1.5 text-sm font-semibold text-link underline-offset-4 hover:underline"
                  >
                    How the audio works
                    <svg
                      className="h-4 w-4"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth={2}
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      aria-hidden="true"
                    >
                      <path d="M5 12h14M13 6l6 6-6 6" />
                    </svg>
                  </Link>
                  <span className="text-xs text-ink-muted">
                    APK is {APP_CONFIG.apkSize} · Android 8.0+
                  </span>
                </div>
              </Reveal>

              <Reveal delay={320}>
                <div className="glass mt-10 flex items-center gap-4 rounded-2xl px-5 py-3">
                  <Waveform bars={14} className="h-7" />
                  <span className="text-xs font-medium text-ink-soft">
                    Opus 48&nbsp;kHz · sub-40&nbsp;ms · encrypted end to end
                  </span>
                </div>
              </Reveal>
            </div>

            <Reveal delay={200} className="lg:col-span-5">
              <PhoneMockup />
            </Reveal>
          </div>

          {/* Stat strip */}
          <Reveal delay={120}>
            <dl className="mt-16 grid grid-cols-2 gap-px overflow-hidden rounded-3xl border border-hairline bg-hairline sm:grid-cols-4 lg:mt-20">
              {STATS.map((stat) => (
                <div
                  key={stat.label}
                  className="bg-surface/60 px-5 py-6 text-center backdrop-blur-xl sm:px-6"
                >
                  <dt className="sr-only">{stat.label}</dt>
                  <dd>
                    <span className="block text-2xl font-bold tracking-tight text-ink sm:text-3xl">
                      {stat.value}
                    </span>
                    <span className="mt-1.5 block text-xs font-medium text-ink-muted">
                      {stat.label}
                    </span>
                  </dd>
                </div>
              ))}
            </dl>
          </Reveal>
        </Container>
      </section>

      {/* ── FEATURES ─────────────────────────────────────────────────── */}
      <Section id="features">
        <Container>
          <Reveal>
            <SectionHeading
              eyebrow="What's inside"
              title="Everything a voice-first group needs"
              description="No meeting links, no scheduling, no waiting rooms. Open a channel and talk — the hard parts run themselves."
            />
          </Reveal>

          <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((feature, i) => (
              <Reveal key={feature.title} delay={i * 70}>
                <GlassCard className="h-full p-7">
                  <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-brand-primary/12 text-link">
                    <Icon name={feature.icon} className="h-6 w-6" />
                  </span>
                  <h3 className="mt-5 text-lg font-semibold text-ink">
                    {feature.title}
                  </h3>
                  <p className="mt-2.5 text-sm leading-relaxed text-ink-soft">
                    {feature.description}
                  </p>
                </GlassCard>
              </Reveal>
            ))}
          </div>

          <Reveal delay={120}>
            <div className="mt-10 text-center">
              <ButtonLink href="/features" variant="glass" size="md">
                See every feature in detail
              </ButtonLink>
            </div>
          </Reveal>
        </Container>
      </Section>

      {/* ── LATENCY ──────────────────────────────────────────────────── */}
      <Section id="latency" className="pt-0">
        <Container>
          <div className="grid items-center gap-12 lg:grid-cols-2 lg:gap-16">
            <Reveal>
              <SectionHeading
                align="left"
                eyebrow="Why it feels different"
                title="Fast enough to interrupt each other"
                description="Latency is what makes a call feel like a conversation instead of a walkie-talkie relay. Talkmos keeps the round trip under 40 ms, so overlapping speech and quick back-and-forth still work."
              />
              <Link
                href="/technology"
                className="mt-7 inline-flex items-center gap-2 text-sm font-semibold text-link underline-offset-4 hover:underline"
              >
                Read the audio pipeline breakdown
                <svg
                  className="h-4 w-4"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={2}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M5 12h14M13 6l6 6-6 6" />
                </svg>
              </Link>
            </Reveal>

            <Reveal delay={120}>
              <GlassCard interactive={false} className="p-7 sm:p-9">
                <p className="text-xs font-semibold uppercase tracking-[0.14em] text-ink-muted">
                  Mouth-to-ear latency
                </p>
                <ul className="mt-7 flex flex-col gap-6">
                  {LATENCY_COMPARISON.map((row) => (
                    <li key={row.label}>
                      <div className="flex items-baseline justify-between gap-4">
                        <span
                          className={`text-sm font-medium ${
                            row.highlight ? "text-ink" : "text-ink-soft"
                          }`}
                        >
                          {row.label}
                        </span>
                        <span
                          className={`font-mono text-sm ${
                            row.highlight ? "font-bold text-link" : "text-ink-muted"
                          }`}
                        >
                          {row.ms} ms
                        </span>
                      </div>
                      <div className="mt-2.5 h-2 w-full overflow-hidden rounded-full bg-ink/8">
                        <div
                          className={`h-full rounded-full ${
                            row.highlight ? "brand-gradient" : "bg-ink/25"
                          }`}
                          style={{ width: `${(row.ms / slowest) * 100}%` }}
                        />
                      </div>
                    </li>
                  ))}
                </ul>
                <p className="mt-7 text-xs leading-relaxed text-ink-muted">
                  Measured on a 4G connection between two devices in the same
                  region, including capture, encode, transit and playout.
                </p>
              </GlassCard>
            </Reveal>
          </div>
        </Container>
      </Section>

      {/* ── HOW IT WORKS ─────────────────────────────────────────────── */}
      <Section id="how-it-works" className="pt-0">
        <Container>
          <Reveal>
            <SectionHeading
              eyebrow="Getting started"
              title="Three steps and you're talking"
              description="From install to first word takes about a minute. There is nothing to configure."
            />
          </Reveal>

          <div className="relative mt-14">
            {/* Connector rail behind the cards on wide screens */}
            <div
              aria-hidden="true"
              className="absolute left-0 right-0 top-12 hidden h-px bg-linear-to-r from-transparent via-brand-primary/35 to-transparent lg:block"
            />
            <ol className="relative grid gap-5 lg:grid-cols-3">
              {STEPS.map((step, i) => (
                <Reveal key={step.step} delay={i * 110} as="li">
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
          </div>
        </Container>
      </Section>

      {/* ── FAQ ──────────────────────────────────────────────────────── */}
      <Section id="faq" className="pt-0">
        <Container size="narrow">
          <Reveal>
            <SectionHeading
              eyebrow="Questions"
              title="Frequently asked"
              description="Still stuck? Support answers email within a business day."
            />
          </Reveal>
          <Reveal delay={100}>
            <Accordion items={FAQS} className="mt-12" />
          </Reveal>
        </Container>
      </Section>

      <CtaBand />
    </>
  );
}
