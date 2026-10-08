import type { ButtonHTMLAttributes } from "react";

type Variant = "primary" | "ghost" | "danger";

const variantClasses: Record<Variant, string> = {
  primary:
    "bg-gradient-to-r from-brand-primary/85 to-brand-secondary/85 hover:from-brand-primary hover:to-brand-secondary border-brand-primary-light/40 text-white",
  ghost:
    "bg-white/5 hover:bg-white/10 border-white/10 text-slate-100",
  danger:
    "bg-gradient-to-b from-rose-500/80 to-rose-600/80 hover:from-rose-500 hover:to-rose-600 border-rose-400/40 text-white",
};

export function Button({
  variant = "primary",
  className = "",
  disabled,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant }) {
  return (
    <button
      disabled={disabled}
      className={`inline-flex items-center justify-center gap-2 rounded-xl border px-4 py-2 text-sm font-medium backdrop-blur-md transition disabled:cursor-not-allowed disabled:opacity-50 ${variantClasses[variant]} ${className}`}
      {...props}
    />
  );
}
