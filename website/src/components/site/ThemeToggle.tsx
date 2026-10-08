"use client";

import { useSyncExternalStore } from "react";

const listeners = new Set<() => void>();

function subscribe(callback: () => void) {
  listeners.add(callback);
  return () => listeners.delete(callback);
}

function getSnapshot() {
  return document.documentElement.classList.contains("dark");
}

// Matches the FOUC-prevention script's default in layout.tsx (no saved
// preference + light OS scheme) so the SSR/hydration pass never mismatches.
function getServerSnapshot() {
  return false;
}

export default function ThemeToggle() {
  const isDark = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);

  const toggle = () => {
    const next = !isDark;
    document.documentElement.classList.toggle("dark", next);
    localStorage.setItem("theme", next ? "dark" : "light");
    listeners.forEach((l) => l());
  };

  return (
    <button
      onClick={toggle}
      type="button"
      aria-label={isDark ? "Switch to light theme" : "Switch to dark theme"}
      className="btn-glass relative flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-ink-soft hover:text-ink"
    >
      {/* Both glyphs are always mounted and cross-faded, so the button
          never reflows when the theme flips. */}
      <svg
        className={`absolute h-[18px] w-[18px] transition-all duration-300 ${
          isDark ? "scale-100 rotate-0 opacity-100" : "scale-50 -rotate-90 opacity-0"
        }`}
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={1.8}
        aria-hidden="true"
      >
        <circle cx="12" cy="12" r="4" />
        <path
          strokeLinecap="round"
          d="M12 2v2m0 16v2M2 12h2m16 0h2M4.9 4.9l1.5 1.5m11.2 11.2 1.5 1.5M19.1 4.9l-1.5 1.5M6.4 17.6l-1.5 1.5"
        />
      </svg>
      <svg
        className={`absolute h-[18px] w-[18px] transition-all duration-300 ${
          isDark ? "scale-50 rotate-90 opacity-0" : "scale-100 rotate-0 opacity-100"
        }`}
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={1.8}
        aria-hidden="true"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M20.4 15.4A9 9 0 1 1 8.6 3.6a7 7 0 0 0 11.8 11.8Z"
        />
      </svg>
    </button>
  );
}
