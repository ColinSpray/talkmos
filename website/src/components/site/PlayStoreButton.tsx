import { APP_CONFIG } from "@/lib/constants";

const SIZES = {
  sm: { box: "px-4 py-2 gap-2.5 rounded-xl", icon: "h-5 w-5", top: "text-[9px]", main: "text-sm" },
  md: { box: "px-5 py-2.5 gap-3 rounded-2xl", icon: "h-6 w-6", top: "text-[10px]", main: "text-base" },
  lg: { box: "px-7 py-3.5 gap-3.5 rounded-2xl", icon: "h-7 w-7", top: "text-[10px]", main: "text-lg" },
};

/** The site's single download CTA. Always points at the live Play Store
 *  listing from APP_CONFIG so there's one URL to change. */
export default function PlayStoreButton({
  size = "md",
  variant = "primary",
  className = "",
}: {
  size?: keyof typeof SIZES;
  variant?: "primary" | "glass";
  className?: string;
}) {
  const s = SIZES[size];
  return (
    <a
      href={APP_CONFIG.playStoreUrl}
      target="_blank"
      rel="noopener noreferrer"
      className={`${variant === "primary" ? "btn-primary" : "btn-glass"} inline-flex items-center font-semibold ${s.box} ${className}`}
    >
      <svg className={`${s.icon} shrink-0`} viewBox="0 0 24 24" aria-hidden="true">
        {/* Four-facet Play mark, each facet drawn as its own path so the
            colours survive on both the gradient and glass variants. */}
        <path fill="#34d399" d="M3.6 2 14.2 12 3.6 22a1.9 1.9 0 0 1-.6-1.4V3.4c0-.55.23-1.05.6-1.4Z" />
        <path fill="#60a5fa" d="M4.9 1.6 17 8.5l-2.9 2.7L4.4 1.5c.16-.02.33 0 .5.1Z" />
        <path fill="#f87171" d="M4.9 22.4c-.17.1-.34.12-.5.1l9.7-9.7 2.9 2.7-12.1 6.9Z" />
        <path fill="#fbbf24" d="m17.9 9 3.2 1.8c.85.5.85 1.4 0 1.9L17.9 15l-3.1-3 3.1-3Z" />
      </svg>
      <span className="flex flex-col text-left leading-none">
        <span className={`${s.top} font-medium uppercase tracking-[0.14em] opacity-75`}>
          Get it on
        </span>
        <span className={`${s.main} mt-1 font-bold tracking-tight`}>Google Play</span>
      </span>
    </a>
  );
}
