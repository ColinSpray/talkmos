/**
 * Decorative audio meter. Bar heights come from a fixed table rather than
 * random values so the server and client render identical markup, and the
 * animation is pure CSS (scaleY) so it never touches the main thread.
 */
const HEIGHTS = [38, 62, 90, 46, 100, 58, 82, 34, 70, 96, 44, 76, 30, 88, 52, 66];

export default function Waveform({
  bars = 16,
  className = "",
  barClassName = "",
}: {
  bars?: number;
  className?: string;
  barClassName?: string;
}) {
  return (
    <div
      className={`flex h-12 items-center gap-[3px] ${className}`}
      aria-hidden="true"
    >
      {Array.from({ length: bars }).map((_, i) => (
        <span
          key={i}
          className={`w-1 origin-center rounded-full bg-linear-to-t from-brand-primary via-brand-secondary to-brand-tertiary ${barClassName}`}
          style={{
            height: `${HEIGHTS[i % HEIGHTS.length]}%`,
            animation: `sound-wave ${1.1 + (i % 4) * 0.18}s ease-in-out ${
              (i % 6) * 0.12
            }s infinite`,
          }}
        />
      ))}
    </div>
  );
}
