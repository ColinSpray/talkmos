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
import { FEATURES, FEATURE_DETAILS } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Features",
  description:
    "Push-to-talk, drop-in voice rooms, on-device neural noise suppression and encrypted audio — every Talkmos feature, explained.",
  alternates: { canonical: "/features" },
};

const EXTRAS = [
  {
    icon: "bell" as const,
    title: "Smart notifications",
    description:
      "Per-room notification rules, so the channels that matter reach you and the noisy ones stay quiet.",
  },
  {
    icon: "battery" as const,
    title: "Low-power standby",
    description:
      "Idle channels cost almost nothing. The radio only wakes when someone actually transmits.",
  },
  {
    icon: "globe" as const,
    title: "Regional edge relays",
    description:
      "Media relays in every major region keep the hop count low wherever your group happens to be.",
  },
  {
    icon: "bolt" as const,
    title: "Instant reconnect",
    description:
      "Switch from Wi-Fi to mobile data mid-sentence and the session survives the handover.",
  },
];

export default function FeaturesPage() {
  return (
    <>
      <section className="pb-6 pt-14 sm:pt-20">
        <Container>
          <Reveal>
            <div className="flex flex-col items-center gap-5 text-center">
              <Eyebrow>Product tour</Eyebrow>
              <h1 className="max-w-3xl text-4xl font-bold tracking-tight text-ink sm:text-5xl lg:text-6xl">
                Built around one idea:{" "}
                <span className="brand-gradient-text">talking should be instant</span>
              </h1>
              <p className="max-w-2xl text-lg leading-relaxed text-ink-soft">
                Every feature below exists to remove a step between thinking of
                something and your group hearing it.
              </p>
              <Waveform bars={24} className="mt-2 h-8 opacity-70" />
            </div>
          </Reveal>
        </Container>
      </section>

      {/* Alternating detail rows */}
      <Section className="pt-16">
        <Container>
          <div className="flex flex-col gap-20 lg:gap-28">
            {FEATURE_DETAILS.map((feature, i) => {
              const flipped = i % 2 === 1;
              return (
                <Reveal key={feature.title} delay={40}>
                  <div className="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
                    <div className={flipped ? "lg:order-2" : ""}>
                      <SectionHeading
                        align="left"
                        eyebrow={feature.eyebrow}
                        title={feature.title}
                        description={feature.description}
                      />
                      <ul className="mt-7 flex flex-col gap-3.5">
                        {feature.points.map((point) => (
                          <li key={point} className="flex items-start gap-3">
                            <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-brand-primary/15 text-link">
                              <svg
                                className="h-3 w-3"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                strokeWidth={3}
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                aria-hidden="true"
                              >
                                <path d="m5 12.5 4.5 4.5L19 7.5" />
                              </svg>
                            </span>
                            <span className="text-sm leading-relaxed text-ink-soft">
                              {point}
                            </span>
                          </li>
                        ))}
                      </ul>
                    </div>

                    {/* Abstract visual — a large glyph on a tinted glass slab */}
                    <div className={flipped ? "lg:order-1" : ""}>
                      <GlassCard
                        interactive={false}
                        className="glass-outline relative overflow-hidden p-10 sm:p-14"
                      >
                        <div
                          aria-hidden="true"
                          className="pointer-events-none absolute -right-10 -top-10 h-44 w-44 rounded-full bg-brand-primary/25 blur-3xl"
                        />
                        <div
                          aria-hidden="true"
                          className="pointer-events-none absolute -bottom-12 -left-8 h-40 w-40 rounded-full bg-brand-secondary/20 blur-3xl"
                        />
                        <div className="relative flex flex-col items-center gap-6">
                          <span className="flex h-24 w-24 items-center justify-center rounded-3xl bg-linear-to-br from-brand-primary/20 to-brand-secondary/15 text-link">
                            <Icon name={feature.icon} className="h-12 w-12" />
                          </span>
                          <Waveform bars={18} className="h-10 opacity-80" />
                          <span className="font-mono text-[11px] uppercase tracking-[0.2em] text-ink-muted">
                            {feature.eyebrow}
                          </span>
                        </div>
                      </GlassCard>
                    </div>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </Container>
      </Section>

      {/* Core feature grid */}
      <Section className="pt-0">
        <Container>
          <Reveal>
            <SectionHeading
              eyebrow="The essentials"
              title="Core capabilities"
              description="The features every Talkmos account gets, free, on day one."
            />
          </Reveal>
          <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((feature, i) => (
              <Reveal key={feature.title} delay={i * 60}>
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
        </Container>
      </Section>

      {/* Smaller extras */}
      <Section className="pt-0">
        <Container>
          <Reveal>
            <SectionHeading
              eyebrow="Details that add up"
              title="Small things, done properly"
            />
          </Reveal>
          <div className="mt-12 grid gap-5 sm:grid-cols-2">
            {EXTRAS.map((extra, i) => (
              <Reveal key={extra.title} delay={i * 60}>
                <GlassCard className="flex h-full items-start gap-4 p-6">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-brand-secondary/12 text-brand-secondary">
                    <Icon name={extra.icon} className="h-5 w-5" />
                  </span>
                  <div>
                    <h3 className="text-base font-semibold text-ink">
                      {extra.title}
                    </h3>
                    <p className="mt-1.5 text-sm leading-relaxed text-ink-soft">
                      {extra.description}
                    </p>
                  </div>
                </GlassCard>
              </Reveal>
            ))}
          </div>
        </Container>
      </Section>

      <CtaBand
        title="Try it on your own group"
        description="Install Talkmos, open a room, and see how much of the friction was the software all along."
        secondary={{ href: "/technology", label: "Audio technology" }}
      />
    </>
  );
}
