import type { Metadata } from "next";
import Link from "next/link";
import Reveal from "@/components/ui/Reveal";
import DeleteAccountForm from "@/components/site/DeleteAccountForm";
import {
  Container,
  Eyebrow,
  GlassCard,
  Section,
} from "@/components/ui/primitives";
import { APP_CONFIG } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Account & Data Deletion",
  description:
    "Request deletion of your Talkmos account and associated data, in line with Google Play's data deletion requirements.",
  alternates: { canonical: "/delete-account" },
};

const DELETED = [
  "Profile, username, avatar and account credentials",
  "Room memberships, contacts and follow lists",
  "Message history and shared stories you created",
  "Push notification tokens and device registrations",
  "Diagnostic logs tied to your account identifier",
];

const RETAINED = [
  {
    what: "Aggregate, anonymised usage counts",
    why: "They carry no identifier and cannot be traced back to you.",
  },
  {
    what: "Transaction and tax records",
    why: "Retained where financial regulations require it, for the statutory period.",
  },
  {
    what: "Abuse and safety records",
    why: "Kept where needed to prevent a banned account from simply re-registering.",
  },
];

export default function DeleteAccountPage() {
  return (
    <>
      <section className="pb-6 pt-14 sm:pt-20">
        <Container>
          <Reveal>
            <div className="flex flex-col items-start gap-5">
              <Eyebrow>Data controls</Eyebrow>
              <h1 className="text-4xl font-bold tracking-tight text-ink sm:text-5xl">
                Delete your account & data
              </h1>
              <p className="max-w-2xl text-lg leading-relaxed text-ink-soft">
                You can close your {APP_CONFIG.name} account from inside the app
                under <strong className="text-ink">Settings → Account</strong>,
                or from this page. Either route does exactly the same thing.
              </p>
            </div>
          </Reveal>
        </Container>
      </section>

      <Section className="pt-8">
        <Container>
          <div className="grid gap-8 lg:grid-cols-12 lg:gap-10">
            <Reveal className="lg:col-span-7">
              <DeleteAccountForm />
            </Reveal>

            <div className="flex flex-col gap-5 lg:col-span-5">
              <Reveal delay={80}>
                <GlassCard interactive={false} className="p-6">
                  <h2 className="text-base font-semibold text-ink">
                    How deletion works
                  </h2>
                  <ol className="mt-4 flex flex-col gap-4">
                    {[
                      {
                        t: "Immediately",
                        d: "Your account is deactivated. You disappear from rooms and contact lists, and nobody can message you.",
                      },
                      {
                        t: "For 30 days",
                        d: "Everything is held in a recoverable state. Sign back in during this window to cancel the request.",
                      },
                      {
                        t: "After 30 days",
                        d: "The purge runs. Personal data is erased permanently and cannot be restored by support.",
                      },
                    ].map((phase, i) => (
                      <li key={phase.t} className="flex gap-3">
                        <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-brand-primary/12 font-mono text-[11px] font-bold text-link">
                          {i + 1}
                        </span>
                        <span>
                          <span className="block text-sm font-semibold text-ink">
                            {phase.t}
                          </span>
                          <span className="mt-1 block text-sm leading-relaxed text-ink-soft">
                            {phase.d}
                          </span>
                        </span>
                      </li>
                    ))}
                  </ol>
                </GlassCard>
              </Reveal>

              <Reveal delay={160}>
                <GlassCard interactive={false} className="p-6">
                  <h2 className="text-base font-semibold text-ink">
                    What gets deleted
                  </h2>
                  <ul className="mt-4 flex flex-col gap-2.5">
                    {DELETED.map((item) => (
                      <li key={item} className="flex gap-3">
                        <span
                          aria-hidden="true"
                          className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-brand-primary/70"
                        />
                        <span className="text-sm leading-relaxed text-ink-soft">
                          {item}
                        </span>
                      </li>
                    ))}
                  </ul>
                </GlassCard>
              </Reveal>
            </div>
          </div>
        </Container>
      </Section>

      <Section className="pt-0 pb-24">
        <Container>
          <Reveal>
            <GlassCard interactive={false} className="p-7 sm:p-9">
              <h2 className="text-xl font-semibold text-ink">
                What we keep, and why
              </h2>
              <p className="mt-2 max-w-2xl text-sm leading-relaxed text-ink-soft">
                A small amount of data survives deletion, either because it no
                longer identifies you or because the law requires it.
              </p>
              <dl className="mt-7 grid gap-px overflow-hidden rounded-2xl border border-hairline bg-hairline sm:grid-cols-3">
                {RETAINED.map((r) => (
                  <div key={r.what} className="bg-surface/70 px-5 py-5 backdrop-blur-xl">
                    <dt className="text-sm font-semibold text-ink">{r.what}</dt>
                    <dd className="mt-2 text-sm leading-relaxed text-ink-soft">
                      {r.why}
                    </dd>
                  </div>
                ))}
              </dl>
              <p className="mt-7 text-sm text-ink-muted">
                Questions about a request already in flight? Email{" "}
                <a
                  href={`mailto:${APP_CONFIG.developer.privacyEmail}`}
                  className="font-medium text-link underline-offset-4 hover:underline"
                >
                  {APP_CONFIG.developer.privacyEmail}
                </a>{" "}
                with your reference ID, or read the{" "}
                <Link
                  href="/privacy"
                  className="font-medium text-link underline-offset-4 hover:underline"
                >
                  Privacy Policy
                </Link>
                .
              </p>
            </GlassCard>
          </Reveal>
        </Container>
      </Section>
    </>
  );
}
