import type { Metadata } from "next";
import Link from "next/link";
import Reveal from "@/components/ui/Reveal";
import Accordion from "@/components/ui/Accordion";
import ContactForm from "@/components/site/ContactForm";
import {
  Container,
  Eyebrow,
  GlassCard,
  Section,
  SectionHeading,
} from "@/components/ui/primitives";
import { APP_CONFIG, FAQS } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Support & Contact",
  description:
    "Get help with Talkmos — technical issues, account questions, privacy requests and abuse reports.",
  alternates: { canonical: "/contact" },
};

const CHANNELS = [
  {
    title: "General support",
    email: APP_CONFIG.developer.email,
    description: "Bugs, audio problems, account access and anything else.",
  },
  {
    title: "Privacy & data requests",
    email: APP_CONFIG.developer.privacyEmail,
    description: "Data access, export and deletion requests under GDPR/CCPA.",
  },
];

export default function ContactPage() {
  return (
    <>
      <section className="pb-8 pt-14 sm:pt-20">
        <Container>
          <Reveal>
            <div className="flex flex-col items-start gap-5">
              <Eyebrow>Support</Eyebrow>
              <h1 className="text-4xl font-bold tracking-tight text-ink sm:text-5xl">
                We&apos;re here to help
              </h1>
              <p className="max-w-2xl text-lg leading-relaxed text-ink-soft">
                Something broken, a privacy question, or a room that needs
                moderating? Send it over — a person reads every message.
              </p>
            </div>
          </Reveal>
        </Container>
      </section>

      <Section className="pt-8">
        <Container>
          <div className="grid gap-8 lg:grid-cols-12 lg:gap-10">
            <Reveal className="lg:col-span-7">
              <ContactForm />
            </Reveal>

            <div className="flex flex-col gap-5 lg:col-span-5">
              {CHANNELS.map((channel, i) => (
                <Reveal key={channel.title} delay={80 + i * 80}>
                  <GlassCard className="p-6">
                    <h2 className="text-base font-semibold text-ink">
                      {channel.title}
                    </h2>
                    <p className="mt-2 text-sm leading-relaxed text-ink-soft">
                      {channel.description}
                    </p>
                    <a
                      href={`mailto:${channel.email}`}
                      className="mt-4 inline-flex items-center gap-2 text-sm font-semibold text-link underline-offset-4 hover:underline"
                    >
                      {channel.email}
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
                    </a>
                  </GlassCard>
                </Reveal>
              ))}

              <Reveal delay={240}>
                <GlassCard interactive={false} className="p-6">
                  <h2 className="text-base font-semibold text-ink">
                    Registered address
                  </h2>
                  <address className="mt-3 text-sm not-italic leading-relaxed text-ink-soft">
                    {APP_CONFIG.developer.name}
                    <br />
                    {APP_CONFIG.developer.address}
                  </address>
                  <p className="mt-4 border-t border-hairline pt-4 text-xs leading-relaxed text-ink-muted">
                    Wanting to close your account? Use the{" "}
                    <Link
                      href="/delete-account"
                      className="font-medium text-link underline-offset-4 hover:underline"
                    >
                      account deletion page
                    </Link>{" "}
                    — it is faster than email.
                  </p>
                </GlassCard>
              </Reveal>
            </div>
          </div>
        </Container>
      </Section>

      <Section id="faq" className="pt-0 pb-24">
        <Container size="narrow">
          <Reveal>
            <SectionHeading
              eyebrow="Before you write"
              title="Frequently asked"
              description="Most support email is one of these six questions."
            />
          </Reveal>
          <Reveal delay={100}>
            <Accordion items={FAQS} className="mt-12" />
          </Reveal>
        </Container>
      </Section>
    </>
  );
}
