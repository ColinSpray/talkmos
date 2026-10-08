const toneClasses = {
  neutral: "bg-white/10 text-slate-200 border-white/15",
  success: "bg-emerald-400/15 text-emerald-300 border-emerald-400/30",
  warning: "bg-amber-400/15 text-amber-300 border-amber-400/30",
  danger: "bg-rose-400/15 text-rose-300 border-rose-400/30",
  info: "bg-sky-400/15 text-sky-300 border-sky-400/30",
} as const;

export function Badge({
  tone = "neutral",
  children,
}: {
  tone?: keyof typeof toneClasses;
  children: React.ReactNode;
}) {
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${toneClasses[tone]}`}
    >
      {children}
    </span>
  );
}
