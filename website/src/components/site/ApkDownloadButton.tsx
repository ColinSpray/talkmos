import { APP_CONFIG } from "@/lib/constants";

const SIZES = {
  sm: { box: "px-4 py-2 gap-2.5 rounded-xl", icon: "h-5 w-5", top: "text-[9px]", main: "text-sm" },
  md: { box: "px-5 py-2.5 gap-3 rounded-2xl", icon: "h-6 w-6", top: "text-[10px]", main: "text-base" },
  lg: { box: "px-7 py-3.5 gap-3.5 rounded-2xl", icon: "h-7 w-7", top: "text-[10px]", main: "text-lg" },
};

/**
 * Direct .apk download, for testers and for devices without the Play
 * Store. The endpoint already sends Content-Disposition: attachment, so
 * the browser saves the file rather than navigating to it — the `download`
 * attribute here is belt-and-braces for the filename.
 */
export default function ApkDownloadButton({
  size = "md",
  variant = "glass",
  className = "",
}: {
  size?: keyof typeof SIZES;
  variant?: "primary" | "glass";
  className?: string;
}) {
  const s = SIZES[size];
  return (
    <a
      href={APP_CONFIG.apkDownloadUrl}
      download="talkmos.apk"
      // The APK is served from a different origin, so this opens a plain
      // cross-origin download rather than being treated as same-site.
      rel="noopener noreferrer"
      className={`${variant === "primary" ? "btn-primary" : "btn-glass"} inline-flex items-center font-semibold ${s.box} ${className}`}
    >
      <svg
        className={`${s.icon} shrink-0`}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth={1.6}
        strokeLinecap="round"
        strokeLinejoin="round"
        aria-hidden="true"
      >
        <path d="M12 3v11" />
        <path d="m7.5 10 4.5 4.5 4.5-4.5" />
        <path d="M4.5 16.5v2a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2v-2" />
      </svg>
      <span className="flex flex-col text-left leading-none">
        <span className={`${s.top} font-medium uppercase tracking-[0.14em] opacity-75`}>
          Direct download
        </span>
        <span className={`${s.main} mt-1 font-bold tracking-tight`}>
          Android APK
        </span>
      </span>
    </a>
  );
}
