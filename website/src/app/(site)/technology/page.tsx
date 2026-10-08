import type { Metadata } from "next";
import Icon from "@/components/Icon";
import Reveal from "@/components/ui/Reveal";
import Waveform from "@/components/site/Waveform";
import CtaBand from "@/components/site/CtaBand";
import {
  Container,
  Eyebrow,
  GlassCard,
  Section,
  SectionHeading,
} from "@/components/ui/primitives";
import {
  LATENCY_COMPARISON,
  PIPELINE_STAGES,
  STATS,
  TECH_SPECS,
} from "@/lib/constants";

export const metadata: Metadata = {
  title: "Audio Technology",
  description:
    "How Talkmos moves voice: Opus at 48 kHz, on-device noise suppression, adaptive jitter buffering and DTLS-SRTP encrypted WebRTC transport.",
  alternates: { canonical: "/technology" },
};

export default function TechnologyPage() {
  const slowest = Math.max(...LATENCY_COMPARISON.map((l) => l.ms));

  return (
    <>
      <section className="pb-4 pt-14 sm:pt-20">
        <Container>
          <Reveal>
            <div className="flex flex-col items-center gap-5 text-center">
              <Eyebrow dot>Live pipeline</Eyebrow>
              <h1 className="max-w-3xl text-4xl font-bold tracking-tight text-ink sm:text-5xl lg:text-6xl">
                What happens between{" "}
                <span className="brand-gradient-text">your mouth and their ear</span>
              </h1>
              <p className="max-w-2xl text-lg leading-relaxed text-ink-soft">
                Four stages, roughly 38 milliseconds. Here is every one of them,
                and the numbers behind them.
              </p>
              <Waveform bars={28} className="mt-3 h-10 opacity-80" />
            </div>
          </Reveal>
        </Container>
      </section>

      {/* Pipeline */}
      <Section>
        <Container>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {PIPELINE_STAGES.map((stage, i) => (
              <Reveal key={stage.title} delay={i * 90}>
                <GlassCard className="relative h-full p-7">
                  <span className="font-mono text-xs font-semibold text-ink-faint">
                    STAGE {String(i + 1).padStart(2, "0")}
                  </span>
                  <span className="mt-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-brand-primary/12 text-link">
                    <Icon name={stage.icon} className="h-6 w-6" />
                  </span>
                  <h2 className="mt-5 text-lg font-semibold text-ink">
                    {stage.title}
                  </h2>
                  <p className="mt-2.5 text-sm leading-relaxed text-ink-soft">
                    {stage.description}
                  </p>
                  {i < PIPELINE_STAGES.length - 1 && (
                    <span
                      aria-hidden="true"
                      className="absolute -right-3 top-1/2 hidden h-6 w-6 -translate-y-1/2 items-center justify-center text-brand-primary/50 lg:flex"
                    >
                      <svg
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth={2}
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      >
                        <path d="M5 12h14M13 6l6 6-6 6" />
                      </svg>
                    </span>
                  )}
                </GlassCard>
              </Reveal>
            ))}
          </div>
        </Container>
      </Section>

      {/* Latency + headline numbers */}
      <Section className="pt-0">
        <Container>
          <div className="grid gap-12 lg:grid-cols-2 lg:gap-16">
            <Reveal>
              <SectionHeading
                align="left"
                eyebrow="Latency budget"
                title="Under 40 ms, end to end"
                description="Each stage gets a fixed slice of the budget. Frames are 20 ms, the jitter buffer starts at 20 ms and only grows when the network forces it, and everything else is measured in microseconds."
              />
              <ul className="mt-8 flex flex-col gap-6">
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
            </Reveal>

            <Reveal delay={120}>
              <div className="grid grid-cols-2 gap-4">
                {STATS.map((stat) => (
                  <GlassCard key={stat.label} className="p-6">
                    <p className="text-2xl font-bold tracking-tight text-ink sm:text-3xl">
                      {stat.value}
                    </p>
                    <p className="mt-2 text-xs font-medium leading-relaxed text-ink-muted">
                      {stat.label}
                    </p>
                  </GlassCard>
                ))}
              </div>
              <GlassCard interactive={false} className="mt-4 p-6">
                <p className="text-xs font-semibold uppercase tracking-[0.14em] text-ink-muted">
                  Adaptive bitrate
                </p>
                <p className="mt-3 text-sm leading-relaxed text-ink-soft">
                  The encoder watches round-trip time and loss, then walks the
                  bitrate between 12 and 64 kbps. On a clean connection you get
                  full-band stereo-width speech; on a train in a tunnel you still
                  get intelligible words instead of a dropped call.
                </p>
              </GlassCard>
            </Reveal>
          </div>
        </Container>
      </Section>

      {/* Spec table */}
      <Section className="pt-0">
        <Container size="narrow">
          <Reveal>
            <SectionHeading
              eyebrow="Reference"
              title="Technical specifications"
              description="The exact configuration the client and relays negotiate."
            />
          </Reveal>
          <Reveal delay={100}>
            <GlassCard interactive={false} className="mt-12 overflow-hidden p-0">
              <dl className="divide-y divide-hairline">
                {TECH_SPECS.map((spec) => (
                  <div
                    key={spec.label}
                    className="flex flex-col gap-1 px-6 py-4 sm:flex-row sm:items-center sm:justify-between sm:gap-8"
                  >
                    <dt className="text-sm font-medium text-ink-soft">
                      {spec.label}
                    </dt>
                    <dd className="font-mono text-sm text-ink">{spec.value}</dd>
                  </div>
                ))}
              </dl>
            </GlassCard>
          </Reveal>

          <Reveal delay={160}>
            <GlassCard interactive={false} className="mt-6 p-6">
              <h2 className="text-base font-semibold text-ink">
                A note on encryption
              </h2>
              <p className="mt-3 text-sm leading-relaxed text-ink-soft">
                Media keys are negotiated per session over DTLS and the audio
                itself travels as SRTP. Relays forward encrypted packets; they
                are not decryption points. Nothing is written to disk during a
                live session, so there is no recording to leak — unless a room
                owner explicitly turns recording on, which is announced to
                everyone in the room.
              </p>
            </GlassCard>
          </Reveal>
        </Container>
      </Section>

      <CtaBand
        title="Hear the difference yourself"
        description="Numbers only go so far. Install Talkmos and put it against whatever you use today."
        secondary={{ href: "/privacy", label: "Privacy policy" }}
      />
    </>
  );
}
