"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { APP_CONFIG, NAV_LINKS } from "@/lib/constants";
import PlayStoreButton from "./PlayStoreButton";
import ApkDownloadButton from "./ApkDownloadButton";
import ThemeToggle from "./ThemeToggle";

// The drawer carries a couple of extra destinations the desktop bar leaves
// to the footer, since there's no footer in view when it's open.
const DRAWER_LINKS = [
  ...NAV_LINKS,
  { name: "Delete Account", href: "/delete-account" },
  { name: "Privacy Policy", href: "/privacy" },
];

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const pathname = usePathname();

  // The bar floats transparently over the hero and only condenses into a
  // solid glass slab once you've scrolled past it.
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // While the drawer is open the page behind it must not scroll.
  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  return (
    <header className="sticky top-0 z-50 w-full">
      <div
        className={`w-full transition-all duration-300 ${
          scrolled || open
            ? "glass border-x-0 border-t-0 shadow-none"
            : "border-b border-transparent bg-transparent"
        }`}
      >
        <nav className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-5 py-3.5 sm:px-6 lg:px-8">
          <Link href="/" className="group flex items-center gap-3">
            <span className="glass-outline relative flex h-10 w-10 items-center justify-center overflow-hidden rounded-xl transition-transform duration-300 group-hover:scale-105">
              <Image
                src="/logo.png"
                alt=""
                width={40}
                height={40}
                className="h-full w-full rounded-xl object-cover"
                priority
              />
            </span>
            <span className="flex flex-col leading-none">
              <span className="text-lg font-bold tracking-tight text-ink">
                {APP_CONFIG.name}
              </span>
              <span className="mt-1 text-[10px] font-semibold uppercase tracking-[0.18em] text-ink-muted">
                Voice engine
              </span>
            </span>
          </Link>

          <div className="hidden items-center gap-1 lg:flex">
            {NAV_LINKS.map((link) => {
              const active = pathname === link.href;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`rounded-xl px-3.5 py-2 text-sm font-medium transition-colors ${
                    active
                      ? "bg-brand-primary/10 text-ink"
                      : "text-ink-soft hover:bg-ink/5 hover:text-ink"
                  }`}
                >
                  {link.name}
                </Link>
              );
            })}
          </div>

          <div className="flex items-center gap-2.5">
            <ThemeToggle />
            <span className="hidden lg:inline-flex">
              <PlayStoreButton size="sm" />
            </span>
            <button
              type="button"
              onClick={() => setOpen((v) => !v)}
              aria-expanded={open}
              aria-label={open ? "Close menu" : "Open menu"}
              className="btn-glass flex h-10 w-10 items-center justify-center rounded-xl text-ink-soft lg:hidden"
            >
              <svg
                className="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={1.8}
                strokeLinecap="round"
                aria-hidden="true"
              >
                {open ? <path d="M6 6l12 12M18 6 6 18" /> : <path d="M4 7h16M4 12h16M4 17h16" />}
              </svg>
            </button>
          </div>
        </nav>
      </div>

      {/* Mobile drawer */}
      <div
        className={`lg:hidden ${open ? "pointer-events-auto" : "pointer-events-none"}`}
      >
        <div
          onClick={() => setOpen(false)}
          className={`fixed inset-0 top-[68px] bg-ink/25 backdrop-blur-[2px] transition-opacity duration-300 ${
            open ? "opacity-100" : "opacity-0"
          }`}
        />
        <div
          className={`glass-panel absolute inset-x-0 top-full origin-top border-x-0 px-5 pb-7 pt-4 transition-all duration-300 ${
            open ? "translate-y-0 opacity-100" : "-translate-y-3 opacity-0"
          }`}
        >
          <div className="flex flex-col gap-1">
            {DRAWER_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setOpen(false)}
                aria-current={pathname === link.href ? "page" : undefined}
                className={`rounded-xl px-3 py-3 text-base font-medium transition-colors hover:bg-ink/5 hover:text-ink ${
                  pathname === link.href ? "bg-brand-primary/10 text-ink" : "text-ink-soft"
                }`}
              >
                {link.name}
              </Link>
            ))}
          </div>
          <div className="mt-5 flex flex-col gap-3">
            <PlayStoreButton size="md" className="w-full justify-center" />
            <ApkDownloadButton size="md" className="w-full justify-center" />
          </div>
        </div>
      </div>
    </header>
  );
}
