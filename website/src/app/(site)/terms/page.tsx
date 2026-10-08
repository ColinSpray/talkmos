import type { Metadata } from "next";
import Link from "next/link";
import LegalShell, {
  LegalList,
  type LegalSection,
} from "@/components/site/LegalShell";
import { APP_CONFIG } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Terms of Service",
  description:
    "The agreement between you and Talkmos Systems Inc. covering acceptable use, accounts, availability and liability.",
  alternates: { canonical: "/terms" },
};

const B = ({ children }: { children: React.ReactNode }) => (
  <strong className="font-semibold text-ink">{children}</strong>
);

const SECTIONS: LegalSection[] = [
  {
    id: "acceptance",
    title: "Acceptance of terms",
    body: (
      <p>
        By installing, accessing or using the <B>{APP_CONFIG.name}</B> mobile
        application or any associated web service provided by{" "}
        <B>{APP_CONFIG.developer.name}</B>, you agree to be bound by these
        Terms. If you do not agree with any part of them, do not use Talkmos.
      </p>
    ),
  },
  {
    id: "eligibility",
    title: "Eligibility",
    body: (
      <p>
        You must be at least 13 years old, or the minimum age of digital consent
        in your jurisdiction if that is higher. By accepting these Terms you
        represent that you meet that requirement, and that you are not barred
        from using the service under any applicable law.
      </p>
    ),
  },
  {
    id: "acceptable-use",
    title: "Acceptable use",
    body: (
      <>
        <p>
          Talkmos carries live voice between real people. We enforce a
          zero-tolerance policy on harmful conduct. You agree not to:
        </p>
        <LegalList
          items={[
            "Transmit content that is illegal, abusive, defamatory, harassing, threatening, or that constitutes hate speech.",
            "Impersonate any person or entity, or misrepresent your affiliation with one.",
            "Record or capture another user's audio without their explicit prior consent.",
            "Distribute spam, unsolicited commercial messages or unauthorised automated bots.",
            "Reverse engineer, decompile or otherwise tamper with the app or our audio infrastructure.",
            "Interfere with the service's operation, or attempt to gain unauthorised access to any account or system.",
          ]}
        />
      </>
    ),
  },
  {
    id: "accounts",
    title: "Your account & security",
    body: (
      <>
        <p>
          You are responsible for keeping your credentials confidential and for
          all activity that occurs under your account. Tell us promptly if you
          suspect unauthorised access.
        </p>
        <p>
          We may suspend or terminate an account that breaches these Terms, and
          in serious cases without prior notice — for example where continued
          access would put other users at risk.
        </p>
      </>
    ),
  },
  {
    id: "content",
    title: "Your content",
    body: (
      <>
        <p>
          You keep ownership of everything you transmit. You grant us a limited,
          non-exclusive licence to transmit, cache and display your content
          strictly as needed to operate the service — routing your audio to the
          people you are talking to, and nothing beyond that.
        </p>
        <p>
          Live audio is relayed rather than stored, so in ordinary use there is
          no copy for us to hold.
        </p>
      </>
    ),
  },
  {
    id: "availability",
    title: "Service availability & changes",
    body: (
      <p>
        Talkmos is provided on an &quot;as is&quot; and &quot;as
        available&quot; basis. We do not warrant uninterrupted or error-free
        operation, and we may add, modify or discontinue features. Where a
        change materially reduces what the service does, we will give notice
        in-app before it takes effect.
      </p>
    ),
  },
  {
    id: "termination",
    title: "Termination",
    body: (
      <p>
        You may stop using Talkmos at any time and delete your account from the
        app or the{" "}
        <Link
          href="/delete-account"
          className="font-medium text-link underline-offset-4 hover:underline"
        >
          deletion page
        </Link>
        . We may terminate or suspend access for breach of these Terms. Sections
        that by their nature should survive termination — liability, governing
        law, and your content licence for material already transmitted — do so.
      </p>
    ),
  },
  {
    id: "liability",
    title: "Limitation of liability",
    body: (
      <p>
        To the maximum extent permitted by law, {APP_CONFIG.developer.name} is
        not liable for indirect, incidental, special, consequential or punitive
        damages, or for lost profits, data or goodwill, arising from your use of
        or inability to use Talkmos. Nothing here limits liability that cannot
        lawfully be limited, including for death or personal injury caused by
        negligence.
      </p>
    ),
  },
  {
    id: "governing-law",
    title: "Governing law & disputes",
    body: (
      <p>
        These Terms are governed by the laws of the State of California, United
        States, without regard to conflict-of-law rules. Disputes will be
        brought in the state or federal courts located in San Francisco County,
        California, unless mandatory consumer-protection law in your country of
        residence gives you the right to bring proceedings locally.
      </p>
    ),
  },
  {
    id: "updates",
    title: "Changes to these terms",
    body: (
      <p>
        We may revise these Terms as the service evolves. The effective date
        above always reflects the current version, and continued use after a
        revision takes effect constitutes acceptance of it.
      </p>
    ),
  },
];

export default function TermsPage() {
  return (
    <LegalShell
      eyebrow="Legal agreement"
      title="Terms of Service"
      intro="The rules that govern your use of Talkmos, written as plainly as a legal document allows."
      meta={[
        { label: "Effective date", value: APP_CONFIG.lastUpdated },
        { label: "Applies to", value: `${APP_CONFIG.name} v${APP_CONFIG.appVersion}` },
        { label: "Provider", value: APP_CONFIG.developer.name },
      ]}
      sections={SECTIONS}
      related={{ href: "/privacy", label: "Privacy Policy" }}
      footer={
        <>
          <h2 className="text-base font-semibold text-ink">Questions about these terms</h2>
          <p className="mt-2 text-sm leading-relaxed text-ink-soft">
            Write to{" "}
            <a
              href={`mailto:${APP_CONFIG.developer.email}`}
              className="font-medium text-link underline-offset-4 hover:underline"
            >
              {APP_CONFIG.developer.email}
            </a>{" "}
            or to {APP_CONFIG.developer.name}, {APP_CONFIG.developer.address}.
          </p>
        </>
      }
    />
  );
}
