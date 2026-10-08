"use client";

import { useState } from "react";

/** Single-open FAQ list. Uses buttons + aria-expanded rather than
 *  <details> so the open/close transition can be animated. */
export default function Accordion({
  items,
  className = "",
}: {
  items: { question: string; answer: string }[];
  className?: string;
}) {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  return (
    <div className={`flex flex-col gap-3 ${className}`}>
      {items.map((item, i) => {
        const open = openIndex === i;
        return (
          <div
            key={item.question}
            className={`glass overflow-hidden rounded-2xl transition-colors duration-300 ${
              open ? "border-brand-primary/35" : ""
            }`}
          >
            <button
              type="button"
              onClick={() => setOpenIndex(open ? null : i)}
              aria-expanded={open}
              className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left sm:px-6 sm:py-5"
            >
              <span className="text-sm font-semibold text-ink sm:text-base">
                {item.question}
              </span>
              <span
                className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full border border-hairline text-ink-soft transition-transform duration-300 ${
                  open ? "rotate-45 border-brand-primary/50 text-link" : ""
                }`}
              >
                <svg
                  className="h-3.5 w-3.5"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={2}
                  strokeLinecap="round"
                  aria-hidden="true"
                >
                  <path d="M12 5v14M5 12h14" />
                </svg>
              </span>
            </button>
            {/* grid-rows 0fr → 1fr animates to the content's natural height
                without needing a measured pixel value. */}
            <div
              className={`grid transition-all duration-300 ease-out ${
                open ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0"
              }`}
            >
              <div className="overflow-hidden">
                <p className="px-5 pb-5 text-sm leading-relaxed text-ink-soft sm:px-6 sm:pb-6">
                  {item.answer}
                </p>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
