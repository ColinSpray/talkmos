import Link from "next/link";
import type { ComponentProps } from "react";

/** Standard page gutter + max width. Every section on the site uses this
 *  so vertical rhythm and edge alignment stay identical page to page. */
export function Container({
  children,
  className = "",
  size = "default",
}: {
  children: React.ReactNode;
  className?: string;
  size?: "default" | "narrow" | "wide";
}) {
  const widths = {
    narrow: "max-w-3xl",
    default: "max-w-6xl",
    wide: "max-w-7xl",
  };
  return (
    <div className={`mx-auto w-full px-5 sm:px-6 lg:px-8 ${widths[size]} ${className}`}>
      {children}
    </div>
  );
}

export function Section({
  children,
  className = "",
  id,
}: {
  children: React.ReactNode;
  className?: string;
  id?: string;
}) {
  return (
    <section id={id} className={`py-20 sm:py-24 lg:py-28 ${className}`}>
      {children}
    </section>
  );
}

/** Small glass pill used above headings and as an inline status marker. */
export function Eyebrow({
  children,
  dot = false,
  className = "",
}: {
  children: React.ReactNode;
  /** Renders a pinging brand dot — reserved for genuinely live things. */
  dot?: boolean;
  className?: string;
}) {
  return (
    <span
      className={`glass inline-flex items-center gap-2 rounded-full px-3.5 py-1.5 text-xs font-semibold tracking-wide text-ink-soft ${className}`}
    >
      {dot && (
        <span className="relative flex h-2 w-2">
          <span className="absolute inline-flex h-full w-full rounded-full bg-brand-primary-light animate-pulse-ring" />
          <span className="relative inline-flex h-2 w-2 rounded-full bg-brand-primary-light" />
        </span>
      )}
      {children}
    </span>
  );
}

export function SectionHeading({
  eyebrow,
  title,
  description,
  align = "center",
  className = "",
}: {
  eyebrow?: string;
  title: React.ReactNode;
  description?: React.ReactNode;
  align?: "center" | "left";
  className?: string;
}) {
  const alignment =
    align === "center" ? "text-center items-center mx-auto" : "text-left items-start";
  return (
    <div className={`flex max-w-2xl flex-col gap-4 ${alignment} ${className}`}>
      {eyebrow && <Eyebrow>{eyebrow}</Eyebrow>}
      <h2 className="text-3xl font-bold tracking-tight text-ink sm:text-4xl lg:text-[2.75rem] lg:leading-[1.1]">
        {title}
      </h2>
      {description && (
        <p className="text-base leading-relaxed text-ink-soft sm:text-lg">{description}</p>
      )}
    </div>
  );
}

export function GlassCard({
  children,
  className = "",
  interactive = true,
}: {
  children: React.ReactNode;
  className?: string;
  /** Off for static containers that shouldn't lift on hover. */
  interactive?: boolean;
}) {
  return (
    <div
      className={`${interactive ? "glass-card" : "glass"} rounded-3xl ${className}`}
    >
      {children}
    </div>
  );
}

type ButtonBaseProps = {
  children: React.ReactNode;
  variant?: "primary" | "glass";
  size?: "sm" | "md" | "lg";
  className?: string;
};

const BUTTON_SIZES = {
  sm: "px-4 py-2 text-sm",
  md: "px-5 py-2.5 text-sm",
  lg: "px-7 py-3.5 text-base",
};

function buttonClasses({
  variant = "primary",
  size = "md",
  className = "",
}: Omit<ButtonBaseProps, "children">) {
  const base =
    "inline-flex items-center justify-center gap-2 rounded-2xl font-semibold whitespace-nowrap disabled:pointer-events-none disabled:opacity-55";
  const style = variant === "primary" ? "btn-primary" : "btn-glass";
  return `${base} ${style} ${BUTTON_SIZES[size]} ${className}`;
}

export function ButtonLink({
  href,
  children,
  variant,
  size,
  className,
  ...rest
}: ButtonBaseProps & ComponentProps<typeof Link>) {
  return (
    <Link href={href} className={buttonClasses({ variant, size, className })} {...rest}>
      {children}
    </Link>
  );
}

export function Button({
  children,
  variant,
  size,
  className,
  ...rest
}: ButtonBaseProps & ComponentProps<"button">) {
  return (
    <button className={buttonClasses({ variant, size, className })} {...rest}>
      {children}
    </button>
  );
}

/** Faint full-bleed rule used between page sections. */
export function Hairline({ className = "" }: { className?: string }) {
  return (
    <div
      aria-hidden="true"
      className={`h-px w-full bg-linear-to-r from-transparent via-hairline to-transparent ${className}`}
    />
  );
}
