"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Fades + lifts its children the first time they scroll into view. The
 * animation itself lives in globals.css (`.reveal[data-visible]`) so the
 * server-rendered markup is already in its hidden state and nothing
 * flashes before hydration.
 */
export default function Reveal({
  children,
  delay = 0,
  className = "",
  as: Tag = "div",
}: {
  children: React.ReactNode;
  /** Stagger, in milliseconds, applied as an animation-delay. */
  delay?: number;
  className?: string;
  as?: "div" | "section" | "li" | "article";
}) {
  const ref = useRef<HTMLElement>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // Anything already on screen at mount (above the fold) reveals right
    // away; the observer disconnects after the first hit so scrolling back
    // up never replays the animation.
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          observer.disconnect();
        }
      },
      { rootMargin: "0px 0px -12% 0px", threshold: 0.05 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <Tag
      // @ts-expect-error — one ref type for the union of allowed tags
      ref={ref}
      data-visible={visible}
      style={delay ? { animationDelay: `${delay}ms` } : undefined}
      className={`reveal ${className}`}
    >
      {children}
    </Tag>
  );
}
