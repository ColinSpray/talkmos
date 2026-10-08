import type { Metadata } from "next";
import LegalShell, {
  LegalList,
  LegalNote,
  type LegalSection,
} from "@/components/site/LegalShell";
import { APP_CONFIG } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Cookie Policy",
  description:
    "Which cookies and local storage keys talkmos.com sets, what each one does, and how to clear them.",
  alternates: { canonical: "/cookies" },
};

const B = ({ children }: { children: React.ReactNode }) => (
  <strong className="font-semibold text-ink">{children}</strong>
);

const SECTIONS: LegalSection[] = [
  {
    id: "what",
    title: "What cookies and local storage are",
    body: (
      <p>
        Cookies are small text files a site stores on your device; local storage
        is a similar browser mechanism that keeps data on the device without
        sending it with every request. Talkmos uses both sparingly — to keep you
        signed in where relevant and to remember interface preferences.
      </p>
    ),
  },
  {
    id: "what-we-set",
    title: "What we actually set",
    body: (
      <>
        <p>
          This website is largely static. In normal browsing it sets exactly one
          thing:
        </p>
        <LegalNote title="Storage used on talkmos.com">
          <LegalList
            items={[
              <>
                <B>theme</B> (local storage) — remembers whether you chose the
                light or dark appearance, so the site does not flash the wrong
                one on your next visit. Contains the literal string
                &quot;light&quot; or &quot;dark&quot;.
              </>,
              <>
                <B>Admin session cookie</B> — set only on the{" "}
                <B>/admin</B> control panel, for staff authentication. It is
                never set for ordinary visitors.
              </>,
            ]}
          />
        </LegalNote>
        <p>
          We do not set advertising cookies, cross-site tracking pixels, or
          third-party analytics cookies on this website.
        </p>
      </>
    ),
  },
  {
    id: "categories",
    title: "Categories we use",
    body: (
      <LegalList
        items={[
          <>
            <B>Strictly necessary.</B> Session authentication and security
            checks for the admin panel. These cannot be switched off without
            breaking sign-in.
          </>,
          <>
            <B>Functional.</B> Interface preferences such as your theme choice.
            Removing them costs you nothing but the preference.
          </>,
        ]}
      />
    ),
  },
  {
    id: "in-app",
    title: "Inside the Android app",
    body: (
      <p>
        The mobile app does not use browser cookies. It stores an authentication
        token and your local preferences in the operating system&apos;s own
        secured app storage, which is removed when you uninstall the app or
        clear its data from Android settings.
      </p>
    ),
  },
  {
    id: "managing",
    title: "Managing and clearing storage",
    body: (
      <>
        <p>You can remove everything this site stores at any time:</p>
        <LegalList
          items={[
            "Browser settings → Privacy → Clear browsing data → Cookies and site data.",
            "Or, per-site: open the padlock icon in the address bar and clear data for talkmos.com.",
            "Blocking storage entirely still lets you browse the site; the theme will simply follow your operating system each visit.",
          ]}
        />
      </>
    ),
  },
  {
    id: "changes",
    title: "Changes to this policy",
    body: (
      <p>
        If we ever add a cookie — for example, privacy-preserving analytics — we
        will list it here and update the date above before it goes live.
      </p>
    ),
  },
];

export default function CookiesPage() {
  return (
    <LegalShell
      eyebrow="Web disclosure"
      title="Cookie Policy"
      intro="A short policy, because there is very little to disclose."
      meta={[
        { label: "Last updated", value: APP_CONFIG.lastUpdated },
        { label: "Applies to", value: "talkmos.com" },
      ]}
      sections={SECTIONS}
      related={{ href: "/privacy", label: "Privacy Policy" }}
      footer={
        <>
          <h2 className="text-base font-semibold text-ink">Still have questions?</h2>
          <p className="mt-2 text-sm leading-relaxed text-ink-soft">
            Email{" "}
            <a
              href={`mailto:${APP_CONFIG.developer.privacyEmail}`}
              className="font-medium text-link underline-offset-4 hover:underline"
            >
              {APP_CONFIG.developer.privacyEmail}
            </a>{" "}
            and we will answer specifics about anything stored on your device.
          </p>
        </>
      }
    />
  );
}
