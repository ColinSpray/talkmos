import type { IconName } from "@/lib/constants";

/** Single stroke-based icon set so every glyph on the site shares the same
 *  weight and 24px grid. Paths are drawn with `currentColor`, so colour is
 *  controlled entirely by the surrounding text colour. */
const PATHS: Record<IconName, React.ReactNode> = {
  microphone: (
    <>
      <path d="M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3Z" />
      <path d="M5 11a7 7 0 0 0 14 0" />
      <path d="M12 18v3" />
    </>
  ),
  sparkles: (
    <>
      <path d="M12 3.5 13.7 8.3 18.5 10 13.7 11.7 12 16.5 10.3 11.7 5.5 10 10.3 8.3 12 3.5Z" />
      <path d="M18.5 15.5 19.3 17.7 21.5 18.5 19.3 19.3 18.5 21.5 17.7 19.3 15.5 18.5 17.7 17.7 18.5 15.5Z" />
    </>
  ),
  walkieTalkie: (
    <>
      <rect x="6" y="8" width="12" height="13" rx="2.5" />
      <path d="M15 8V5a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v3" />
      <path d="M17 4.5 19.5 2" />
      <path d="M9.5 12.5h5" />
      <path d="M9.5 16.5h5" />
    </>
  ),
  shieldCheck: (
    <>
      <path d="M12 3 5 6v5.5c0 4.4 2.9 8.3 7 9.5 4.1-1.2 7-5.1 7-9.5V6l-7-3Z" />
      <path d="m9.2 12.2 2 2 3.6-3.9" />
    </>
  ),
  cpu: (
    <>
      <rect x="7" y="7" width="10" height="10" rx="2" />
      <path d="M10.5 10.5h3v3h-3z" />
      <path d="M10 4v3M14 4v3M10 17v3M14 17v3M4 10h3M4 14h3M17 10h3M17 14h3" />
    </>
  ),
  globe: (
    <>
      <circle cx="12" cy="12" r="8.5" />
      <path d="M3.5 12h17" />
      <path d="M12 3.5c2.2 2.4 3.3 5.3 3.3 8.5S14.2 18.1 12 20.5c-2.2-2.4-3.3-5.3-3.3-8.5S9.8 5.9 12 3.5Z" />
    </>
  ),
  waveform: (
    <>
      <path d="M3 12h2M9 5v14M15 8v8M21 12h-2M6 9v6M12 3v18M18 6v12" />
    </>
  ),
  bolt: <path d="M13.5 2.5 5 13.5h5.5L10 21.5 19 10.5h-5.5l0-8Z" />,
  users: (
    <>
      <circle cx="9.5" cy="8.5" r="3.5" />
      <path d="M3.5 20a6 6 0 0 1 12 0" />
      <path d="M16 5.2a3.5 3.5 0 0 1 0 6.6" />
      <path d="M17.6 14.6A6 6 0 0 1 20.5 20" />
    </>
  ),
  lock: (
    <>
      <rect x="5" y="10.5" width="14" height="10" rx="2.5" />
      <path d="M8.5 10.5V7.8a3.5 3.5 0 0 1 7 0v2.7" />
      <path d="M12 14.5v2.5" />
    </>
  ),
  bell: (
    <>
      <path d="M18 15.5V11a6 6 0 1 0-12 0v4.5L4.5 18h15L18 15.5Z" />
      <path d="M10 21h4" />
    </>
  ),
  battery: (
    <>
      <rect x="3" y="8" width="15" height="8" rx="2.5" />
      <path d="M21 11v2" />
      <path d="M6.5 11h4" />
    </>
  ),
};

export default function Icon({
  name,
  className = "h-6 w-6",
}: {
  name: IconName;
  className?: string;
}) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.6}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      {PATHS[name]}
    </svg>
  );
}
