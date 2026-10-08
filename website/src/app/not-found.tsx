import Link from "next/link";
import Image from "next/image";
import { NAV_LINKS } from "@/lib/constants";
import { ButtonLink } from "@/components/ui/primitives";

/** Global 404. It renders outside the (site) group, so it paints its own
 *  aurora backdrop and a minimal way back rather than the full chrome. */
export default function NotFound() {
  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center px-5 py-20 text-center text-ink">
      <div className="aurora" aria-hidden="true" />
      <div className="grain" aria-hidden="true" />

      <div className="glow-halo">
        <Link href="/" className="glass glass-outline block rounded-3xl p-4">
          <Image
            src="/logo.png"
            alt="Talkmos"
            width={64}
            height={64}
            className="rounded-2xl"
            priority
          />
        </Link>
      </div>

      <p className="mt-10 font-mono text-sm font-semibold tracking-[0.3em] text-ink-muted">
        404
      </p>
      <h1 className="mt-4 max-w-lg text-3xl font-bold tracking-tight sm:text-4xl">
        This channel doesn&apos;t exist
      </h1>
      <p className="mt-4 max-w-md text-base leading-relaxed text-ink-soft">
        The page you were looking for has moved, or never existed. The link may
        have been mistyped.
      </p>

      <div className="mt-9 flex flex-col gap-3 sm:flex-row">
        <ButtonLink href="/" size="md">
          Back to home
        </ButtonLink>
        <ButtonLink href="/contact" variant="glass" size="md">
          Contact support
        </ButtonLink>
      </div>

      <nav className="mt-12 flex flex-wrap items-center justify-center gap-x-6 gap-y-3">
        {NAV_LINKS.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className="text-sm text-ink-muted underline-offset-4 transition-colors hover:text-ink hover:underline"
          >
            {link.name}
          </Link>
        ))}
      </nav>
    </div>
  );
}
