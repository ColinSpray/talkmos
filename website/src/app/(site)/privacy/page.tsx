import type { Metadata } from "next";
import Link from "next/link";
import LegalShell, {
  LegalList,
  LegalNote,
  type LegalSection,
} from "@/components/site/LegalShell";
import { APP_CONFIG } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "How Talkmos collects, uses, shares and protects your data — written to satisfy Google Play's Developer Programme policies.",
  alternates: { canonical: "/privacy" },
};

const B = ({ children }: { children: React.ReactNode }) => (
  <strong className="font-semibold text-ink">{children}</strong>
);

const SECTIONS: LegalSection[] = [
  {
    id: "overview",
    title: "Overview & commitment",
    body: (
      <>
        <p>
          <B>{APP_CONFIG.name}</B> (&quot;we&quot;, &quot;us&quot;,
          &quot;our&quot;), operated by <B>{APP_CONFIG.developer.name}</B>,
          builds real-time voice communication tools. This policy explains what
          we collect, why, who it is shared with, and the controls you have.
        </p>
        <p>
          It applies to the Talkmos Android application distributed on Google
          Play, and to our website at <B>talkmos.com</B>. It does not apply to
          third-party services you reach through links we publish.
        </p>
      </>
    ),
  },
  {
    id: "what-we-collect",
    title: "Information we collect",
    body: (
      <>
        <p>
          We collect the minimum needed to run a voice service, in three
          categories:
        </p>
        <LegalList
          items={[
            <>
              <B>Account information.</B> Your username, email address and, if
              you set one, an avatar image. Provided by you at registration.
            </>,
            <>
              <B>Voice and audio streams.</B> Live microphone audio captured
              during an active session. Packets are relayed in real time over
              WebRTC/SRTP and are <em>not</em> written to storage once a session
              ends, unless a room owner has explicitly enabled recording.
            </>,
            <>
              <B>Device and diagnostic data.</B> IP address, device model,
              operating system version, app version, crash traces and push
              notification tokens. Used for connectivity and stability, not
              profiling.
            </>,
          ]}
        />
        <LegalNote title="Android permissions requested">
          <LegalList
            items={[
              <>
                <B>RECORD_AUDIO</B> — captures your voice while you are
                transmitting in push-to-talk or an active room. Session-scoped.
              </>,
              <>
                <B>INTERNET / ACCESS_NETWORK_STATE</B> — establishes and
                maintains connections to voice relays.
              </>,
              <>
                <B>POST_NOTIFICATIONS</B> (optional) — alerts you when someone
                speaks in a room you follow.
              </>,
              <>
                <B>BLUETOOTH_CONNECT</B> (optional) — routes audio to wireless
                headsets and car systems.
              </>,
            ]}
          />
        </LegalNote>
      </>
    ),
  },
  {
    id: "how-we-use",
    title: "How we use your information",
    body: (
      <>
        <LegalList
          items={[
            "Establishing, maintaining and optimising low-latency audio sessions.",
            "Authenticating your account and protecting access to private channels.",
            "Detecting and preventing fraud, abuse and unauthorised access.",
            "Diagnosing crashes and improving performance across Android device models.",
            "Sending service notifications you have opted into.",
          ]}
        />
        <p>
          We do not use your voice or message content to build advertising
          profiles, and we do not train models on your audio.
        </p>
      </>
    ),
  },
  {
    id: "sharing",
    title: "Data sharing & third-party services",
    body: (
      <>
        <p>
          We do <B>not</B> sell, rent or trade personal data or voice content.
          We rely on a small number of processors to operate the service:
        </p>
        <LegalList
          items={[
            <>
              <B>Google Play Services</B> — app distribution, integrity
              verification and push delivery via FCM.
            </>,
            <>
              <B>Firebase Crashlytics</B> — crash reporting so we can fix
              stability issues.
            </>,
            <>
              <B>WebRTC STUN/TURN infrastructure</B> — NAT traversal and media
              relay. Relays forward encrypted packets and are not decryption
              points.
            </>,
          ]}
        />
        <p>
          We may also disclose data where legally compelled, or where necessary
          to protect the safety of our users.
        </p>
      </>
    ),
  },
  {
    id: "security",
    title: "Security & retention",
    body: (
      <>
        <p>
          Media keys are negotiated per session over DTLS, and audio travels as
          SRTP. Account data is encrypted at rest and access is restricted to
          staff who need it.
        </p>
        <LegalList
          items={[
            "Live audio: relayed, not stored. Discarded as soon as it is delivered.",
            "Account data: retained while your account is active.",
            "Diagnostic logs: retained up to 90 days, then rotated out.",
            "Deleted accounts: purged permanently after the 30-day grace period.",
          ]}
        />
      </>
    ),
  },
  {
    id: "your-rights",
    title: "Your rights & choices",
    body: (
      <>
        <p>
          Depending on where you live, you may have rights to access, correct,
          export or erase your personal data, and to object to certain
          processing. You can exercise all of these without contacting us:
        </p>
        <LegalList
          items={[
            <>
              <B>Access & export</B> — Settings → Account → Export data, in the
              app.
            </>,
            <>
              <B>Deletion</B> — Settings → Account → Delete account, or the{" "}
              <Link
                href="/delete-account"
                className="font-medium text-link underline-offset-4 hover:underline"
              >
                deletion page
              </Link>
              .
            </>,
            <>
              <B>Notifications</B> — revoke the permission from Android system
              settings at any time.
            </>,
          ]}
        />
        <p>
          For anything we cannot handle in-app, write to{" "}
          <a
            href={`mailto:${APP_CONFIG.developer.privacyEmail}`}
            className="font-medium text-link underline-offset-4 hover:underline"
          >
            {APP_CONFIG.developer.privacyEmail}
          </a>
          . We respond within 30 days.
        </p>
      </>
    ),
  },
  {
    id: "children",
    title: "Children's privacy",
    body: (
      <p>
        Talkmos is not directed at children under 13, and we do not knowingly
        collect their data. If you believe a child has registered, contact{" "}
        <a
          href={`mailto:${APP_CONFIG.developer.privacyEmail}`}
          className="font-medium text-link underline-offset-4 hover:underline"
        >
          {APP_CONFIG.developer.privacyEmail}
        </a>{" "}
        and we will remove the account.
      </p>
    ),
  },
  {
    id: "changes",
    title: "Changes to this policy",
    body: (
      <p>
        We will update this page when our practices change, and revise the
        &quot;last updated&quot; date above. Material changes are announced
        in-app before they take effect, so you have a chance to review them.
      </p>
    ),
  },
];

export default function PrivacyPage() {
  return (
    <LegalShell
      eyebrow="Google Play compliant document"
      title="Privacy Policy"
      intro="What we collect, why we collect it, who we share it with, and how to make us stop."
      meta={[
        { label: "Last updated", value: APP_CONFIG.lastUpdated },
        { label: "App version", value: `v${APP_CONFIG.appVersion}` },
        { label: "Developer", value: APP_CONFIG.developer.name },
      ]}
      sections={SECTIONS}
      related={{ href: "/terms", label: "Terms of Service" }}
      footer={
        <>
          <h2 className="text-base font-semibold text-ink">Contact the data controller</h2>
          <address className="mt-3 text-sm not-italic leading-relaxed text-ink-soft">
            {APP_CONFIG.developer.name}
            <br />
            {APP_CONFIG.developer.address}
            <br />
            <a
              href={`mailto:${APP_CONFIG.developer.privacyEmail}`}
              className="font-medium text-link underline-offset-4 hover:underline"
            >
              {APP_CONFIG.developer.privacyEmail}
            </a>
          </address>
        </>
      }
    />
  );
}
