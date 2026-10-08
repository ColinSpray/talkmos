import Link from "next/link";
import { Container, Eyebrow, Hairline } from "@/components/ui/primitives";

export type LegalSection = {
  id: string;
  title: string;
  body: React.ReactNode;
};

/** Shared chrome for the three policy pages: header block, sticky table of
 *  contents, and numbered sections with consistent prose styling. */
export default function LegalShell({
  eyebrow,
  title,
  intro,
  meta,
  sections,
  footer,
  related,
}: {
  eyebrow: string;
  title: string;
  intro: string;
  meta: { label: string; value: string }[];
  sections: LegalSection[];
  footer?: React.ReactNode;
  /** Sibling policy to point at in the closing line — each page passes one
   *  that isn't itself. */
  related: { href: string; label: string };
}) {
  return (
    <div className="pb-16 pt-14 sm:pt-20">
      <Container>
        <div className="flex flex-col items-start gap-5">
          <Eyebrow>{eyebrow}</Eyebrow>
          <h1 className="text-4xl font-bold tracking-tight text-ink sm:text-5xl">
            {title}
          </h1>
          <p className="max-w-2xl text-base leading-relaxed text-ink-soft sm:text-lg">
            {intro}
          </p>
          <dl className="mt-2 flex flex-wrap gap-x-8 gap-y-3">
            {meta.map((m) => (
              <div key={m.label}>
                <dt className="text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-muted">
                  {m.label}
                </dt>
                <dd className="mt-1 text-sm font-medium text-ink">{m.value}</dd>
              </div>
            ))}
          </dl>
        </div>

        <Hairline className="my-10" />

        <div className="grid gap-10 lg:grid-cols-12 lg:gap-12">
          {/* Table of contents — sticky on desktop, a plain list on mobile */}
          <nav
            aria-label="On this page"
            className="lg:col-span-4 lg:sticky lg:top-28 lg:self-start"
          >
            <div className="glass rounded-3xl p-5">
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-muted">
                On this page
              </p>
              <ol className="mt-4 flex flex-col gap-1">
                {sections.map((s, i) => (
                  <li key={s.id}>
                    <a
                      href={`#${s.id}`}
                      className="flex items-start gap-3 rounded-xl px-3 py-2 text-sm text-ink-soft transition-colors hover:bg-ink/5 hover:text-ink"
                    >
                      <span className="mt-0.5 font-mono text-[11px] text-ink-faint">
                        {String(i + 1).padStart(2, "0")}
                      </span>
                      {s.title}
                    </a>
                  </li>
                ))}
              </ol>
            </div>
          </nav>

          <div className="lg:col-span-8">
            <div className="flex flex-col gap-12">
              {sections.map((s, i) => (
                <section key={s.id} id={s.id} className="scroll-mt-28">
                  <h2 className="flex items-center gap-3 text-xl font-semibold text-ink sm:text-2xl">
                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-brand-primary/12 font-mono text-xs font-bold text-link">
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    {s.title}
                  </h2>
                  <div className="legal-prose mt-4 flex flex-col gap-4 text-sm leading-relaxed text-ink-soft sm:text-base">
                    {s.body}
                  </div>
                </section>
              ))}
            </div>

            {footer && (
              <div className="glass mt-12 rounded-3xl p-6">{footer}</div>
            )}

            <p className="mt-10 text-sm text-ink-muted">
              Looking for something else?{" "}
              <Link
                href="/contact"
                className="font-medium text-link underline-offset-4 hover:underline"
              >
                Contact support
              </Link>{" "}
              or read the{" "}
              <Link
                href={related.href}
                className="font-medium text-link underline-offset-4 hover:underline"
              >
                {related.label}
              </Link>
              .
            </p>
          </div>
        </div>
      </Container>
    </div>
  );
}

/** Callout used inside legal bodies for permission lists, warnings, etc. */
export function LegalNote({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="glass rounded-2xl p-5">
      <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-link">
        {title}
      </p>
      <div className="mt-3 flex flex-col gap-2 text-sm text-ink-soft">
        {children}
      </div>
    </div>
  );
}

/** Bulleted list with the site's marker styling. */
export function LegalList({ items }: { items: React.ReactNode[] }) {
  return (
    <ul className="flex flex-col gap-2.5">
      {items.map((item, i) => (
        <li key={i} className="flex gap-3">
          <span
            aria-hidden="true"
            className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-brand-primary/70"
          />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}
