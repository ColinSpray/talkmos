import Link from "next/link";
import Image from "next/image";
import { APP_CONFIG, FOOTER_SECTIONS } from "@/lib/constants";
import { Container } from "@/components/ui/primitives";
import PlayStoreButton from "./PlayStoreButton";
import ApkDownloadButton from "./ApkDownloadButton";

export default function Footer() {
  return (
    <footer className="relative mt-auto pt-16">
      <Container size="wide">
        <div className="glass rounded-t-4xl border-b-0 px-6 py-12 sm:px-10 lg:px-14">
          <div className="grid grid-cols-2 gap-10 sm:grid-cols-3 lg:grid-cols-12 lg:gap-8">
            <div className="col-span-2 sm:col-span-3 lg:col-span-4">
              <Link href="/" className="flex items-center gap-3">
                <Image
                  src="/logo.png"
                  alt=""
                  width={44}
                  height={44}
                  className="rounded-xl"
                />
                <span className="text-lg font-bold tracking-tight text-ink">
                  {APP_CONFIG.name}
                </span>
              </Link>
              <p className="mt-4 max-w-xs text-sm leading-relaxed text-ink-soft">
                {APP_CONFIG.tagline}. Built for groups who would rather talk
                than type.
              </p>
              <div className="mt-6 flex flex-wrap gap-3">
                <PlayStoreButton size="sm" variant="glass" />
                <ApkDownloadButton size="sm" />
              </div>
            </div>

            {FOOTER_SECTIONS.map((section) => (
              <div key={section.title} className="lg:col-span-2">
                <h3 className="text-xs font-semibold uppercase tracking-[0.16em] text-ink-muted">
                  {section.title}
                </h3>
                <ul className="mt-4 flex flex-col gap-3">
                  {section.links.map((link) => (
                    <li key={link.href}>
                      <Link
                        href={link.href}
                        className="text-sm text-ink-soft transition-colors hover:text-ink"
                      >
                        {link.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}

            <div className="col-span-2 sm:col-span-3 lg:col-span-2">
              <h3 className="text-xs font-semibold uppercase tracking-[0.16em] text-ink-muted">
                Contact
              </h3>
              <ul className="mt-4 flex flex-col gap-3 text-sm text-ink-soft">
                <li>
                  <a
                    href={`mailto:${APP_CONFIG.developer.email}`}
                    className="transition-colors hover:text-ink"
                  >
                    {APP_CONFIG.developer.email}
                  </a>
                </li>
                <li>
                  <a
                    href={`mailto:${APP_CONFIG.developer.privacyEmail}`}
                    className="transition-colors hover:text-ink"
                  >
                    {APP_CONFIG.developer.privacyEmail}
                  </a>
                </li>
                <li className="leading-relaxed text-ink-muted">
                  {APP_CONFIG.developer.address}
                </li>
              </ul>
            </div>
          </div>

          <div className="mt-12 flex flex-col gap-4 border-t border-hairline pt-6 text-xs text-ink-muted sm:flex-row sm:items-center sm:justify-between">
            <p>
              © {new Date().getFullYear()} {APP_CONFIG.developer.name}. All
              rights reserved.
            </p>
            <p className="flex flex-wrap items-center gap-x-3 gap-y-1">
              <span>
                {APP_CONFIG.name} v{APP_CONFIG.appVersion}
              </span>
              <span aria-hidden="true">•</span>
              <span>Updated {APP_CONFIG.lastUpdated}</span>
              <span aria-hidden="true">•</span>
              <span>Android {APP_CONFIG.packageName}</span>
            </p>
          </div>
        </div>
      </Container>
    </footer>
  );
}
