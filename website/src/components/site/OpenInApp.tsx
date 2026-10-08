"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import PlayStoreButton from "./PlayStoreButton";
import Waveform from "./Waveform";

/**
 * Universal/App Link landing page. Android and iOS both try to hand this
 * exact https URL straight to the app first (see the intent-filters /
 * associated-domains config) — this page only renders when that hand-off
 * didn't happen: app not installed, domain verification not yet in effect,
 * or a desktop browser. It makes one more attempt via the custom scheme,
 * then falls back to a Play Store prompt if that doesn't do anything.
 */
export default function OpenInApp({
  appUrl,
  title,
  subtitle,
}: {
  /** talkmos://… deep link to attempt */
  appUrl: string;
  title: string;
  subtitle: string;
}) {
  const [showFallback, setShowFallback] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setShowFallback(true), 1600);
    // If the timeout fires, nothing happened — had the app taken over, this
    // page would have been navigated away from. The fallback is scheduled
    // regardless, so this is simply the earliest possible attempt.
    window.location.href = appUrl;
    return () => clearTimeout(timer);
  }, [appUrl]);

  return (
    <div className="flex min-h-[78vh] flex-col items-center justify-center px-5 py-20 text-center">
      <div className="glow-halo">
        <div className="glass glass-outline rounded-3xl p-4">
          <Image
            src="/logo.png"
            alt="Talkmos"
            width={72}
            height={72}
            className="rounded-2xl"
            priority
          />
        </div>
      </div>

      <h1 className="mt-8 max-w-md text-2xl font-bold tracking-tight text-ink sm:text-3xl">
        {title}
      </h1>
      <p className="mt-3 max-w-sm text-sm leading-relaxed text-ink-soft">
        {subtitle}
      </p>

      <Waveform bars={16} className="mt-8 h-7 opacity-70" />
      <p className="mt-3 text-xs font-medium text-ink-muted">
        Opening the Talkmos app…
      </p>

      <div
        className={`mt-10 flex flex-col items-center gap-4 transition-opacity duration-500 ${
          showFallback ? "opacity-100" : "opacity-0"
        }`}
      >
        <div className="glass rounded-2xl px-5 py-4">
          <p className="text-sm font-medium text-ink">Nothing happened?</p>
          <p className="mt-1 text-xs text-ink-soft">
            Install Talkmos, then open this link again.
          </p>
        </div>
        <PlayStoreButton size="md" />
        <Link
          href="/"
          className="text-xs font-medium text-ink-muted underline-offset-4 transition-colors hover:text-ink hover:underline"
        >
          Go to talkmos.com instead
        </Link>
      </div>
    </div>
  );
}
