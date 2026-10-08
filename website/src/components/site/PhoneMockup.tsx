"use client";

import { useState } from "react";
import Image from "next/image";
import Waveform from "./Waveform";

const PARTICIPANTS = [
  { name: "Aria", role: "Speaking", active: true, hue: "from-brand-primary to-brand-secondary" },
  { name: "Noor", role: "Listening", active: false, hue: "from-brand-tertiary to-brand-primary" },
  { name: "Kai", role: "Listening", active: false, hue: "from-brand-secondary to-brand-tertiary" },
];

/** In-hero device mock. The push-to-talk button is genuinely interactive —
 *  press it and the room state changes — which sells the interaction far
 *  better than a static screenshot would. */
export default function PhoneMockup() {
  const [talking, setTalking] = useState(false);

  return (
    <div className="relative mx-auto w-full max-w-[19rem] sm:max-w-[21rem]">
      {/* Floating glass chips anchored to the device corners */}
      <div className="glass absolute -left-6 top-24 z-20 hidden animate-float rounded-2xl px-3.5 py-2.5 sm:block">
        <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-ink-muted">
          Latency
        </p>
        <p className="text-lg font-bold text-ink">38 ms</p>
      </div>
      <div className="glass absolute -right-5 bottom-32 z-20 hidden animate-float-slow rounded-2xl px-3.5 py-2.5 sm:block">
        <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-ink-muted">
          Noise removed
        </p>
        <p className="text-lg font-bold text-ink">−32 dB</p>
      </div>

      <div className="glow-halo">
        <div className="glass glass-outline rounded-[2.75rem] p-2.5 shadow-[var(--glass-shadow-lg)]">
          <div className="relative overflow-hidden rounded-[2.15rem] bg-linear-to-b from-brand-primary/12 via-transparent to-brand-secondary/12 p-5">
            {/* Status bar */}
            <div className="flex items-center justify-between text-[11px] font-medium text-ink-muted">
              <span>9:41</span>
              <span className="flex items-center gap-1.5">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                Connected
              </span>
            </div>

            {/* Room header */}
            <div className="mt-6 flex items-center gap-3">
              <Image
                src="/logo.png"
                alt=""
                width={36}
                height={36}
                className="rounded-xl"
              />
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold text-ink">
                  Design Standup
                </p>
                <p className="text-[11px] text-ink-muted">3 in the room · Opus 48kHz</p>
              </div>
            </div>

            {/* Participants */}
            <ul className="mt-5 flex flex-col gap-2.5">
              {PARTICIPANTS.map((p) => {
                const isLive = p.active && !talking;
                return (
                  <li
                    key={p.name}
                    className={`glass flex items-center gap-3 rounded-2xl px-3 py-2.5 transition-colors duration-300 ${
                      isLive ? "border-brand-primary/40" : ""
                    }`}
                  >
                    <span
                      className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-linear-to-br ${p.hue} text-[11px] font-bold text-white`}
                    >
                      {p.name[0]}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-xs font-semibold text-ink">
                        {p.name}
                      </span>
                      <span className="block text-[10px] text-ink-muted">
                        {talking && p.active ? "Listening" : p.role}
                      </span>
                    </span>
                    {isLive && (
                      <Waveform bars={4} className="h-4 gap-[2px]" barClassName="w-[3px]" />
                    )}
                  </li>
                );
              })}
            </ul>

            {/* Push to talk */}
            <div className="mt-6 flex flex-col items-center gap-3">
              <button
                type="button"
                onPointerDown={() => setTalking(true)}
                onPointerUp={() => setTalking(false)}
                onPointerLeave={() => setTalking(false)}
                aria-pressed={talking}
                aria-label="Demo push to talk"
                className={`relative flex h-16 w-16 items-center justify-center rounded-full text-white transition-transform duration-200 ${
                  talking ? "scale-95 brand-gradient" : "brand-gradient"
                }`}
              >
                {talking && (
                  <span className="absolute inset-0 animate-pulse-ring rounded-full bg-brand-primary/50" />
                )}
                <svg
                  className="relative h-7 w-7"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={1.8}
                  strokeLinecap="round"
                  aria-hidden="true"
                >
                  <path d="M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3Z" />
                  <path d="M5 11a7 7 0 0 0 14 0M12 18v3" />
                </svg>
              </button>
              <p className="text-[11px] font-medium text-ink-muted">
                {talking ? "You're live — release to stop" : "Hold to talk"}
              </p>
              <Waveform
                bars={22}
                className={`h-8 w-full justify-center transition-opacity duration-300 ${
                  talking ? "opacity-100" : "opacity-30"
                }`}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
