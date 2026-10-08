"use client";

import { useState } from "react";
import { Button } from "@/components/ui/primitives";
import { APP_CONFIG, CONTACT_TOPICS } from "@/lib/constants";

const FIELD =
  "glass-input rounded-2xl px-4 py-3 text-sm outline-none";
const LABEL =
  "mb-2 block text-xs font-semibold uppercase tracking-[0.12em] text-ink-muted";

/**
 * There is no inbound-mail backend yet, so submitting hands the message to
 * the visitor's own mail client pre-addressed to support. That keeps the
 * form honest: nothing is silently swallowed.
 */
export default function ContactForm() {
  const [sent, setSent] = useState(false);
  const [form, setForm] = useState({
    name: "",
    email: "",
    topic: CONTACT_TOPICS[0],
    message: "",
  });

  const set = (key: keyof typeof form) => (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const body = [
      `Name: ${form.name}`,
      `Email: ${form.email}`,
      `Topic: ${form.topic}`,
      "",
      form.message,
    ].join("\n");
    window.location.href = `mailto:${APP_CONFIG.developer.email}?subject=${encodeURIComponent(
      `[${form.topic}] Talkmos support request`
    )}&body=${encodeURIComponent(body)}`;
    setSent(true);
  };

  if (sent) {
    return (
      <div className="glass flex flex-col items-center gap-4 rounded-3xl px-6 py-12 text-center">
        <span className="flex h-14 w-14 items-center justify-center rounded-full bg-brand-primary/15 text-link">
          <svg
            className="h-7 w-7"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={1.8}
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <path d="m5 12.5 4.5 4.5L19 7.5" />
          </svg>
        </span>
        <h3 className="text-lg font-semibold text-ink">Your mail client is open</h3>
        <p className="max-w-sm text-sm leading-relaxed text-ink-soft">
          Send the drafted message and our support team will reply within one
          business day. If nothing opened, email us directly at{" "}
          <a
            className="font-medium text-link underline-offset-4 hover:underline"
            href={`mailto:${APP_CONFIG.developer.email}`}
          >
            {APP_CONFIG.developer.email}
          </a>
          .
        </p>
        <Button variant="glass" size="sm" onClick={() => setSent(false)}>
          Write another message
        </Button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="glass rounded-3xl p-6 sm:p-8">
      <h2 className="text-xl font-semibold text-ink">Send us a message</h2>
      <p className="mt-2 text-sm text-ink-soft">
        Tell us what is going on and we will get back to you by email.
      </p>

      <div className="mt-6 grid gap-5 sm:grid-cols-2">
        <div>
          <label className={LABEL} htmlFor="contact-name">
            Your name
          </label>
          <input
            id="contact-name"
            required
            value={form.name}
            onChange={set("name")}
            placeholder="Alex Rivera"
            className={FIELD}
          />
        </div>
        <div>
          <label className={LABEL} htmlFor="contact-email">
            Email address
          </label>
          <input
            id="contact-email"
            type="email"
            required
            value={form.email}
            onChange={set("email")}
            placeholder="you@example.com"
            className={FIELD}
          />
        </div>
        <div className="sm:col-span-2">
          <label className={LABEL} htmlFor="contact-topic">
            Topic
          </label>
          <select
            id="contact-topic"
            value={form.topic}
            onChange={set("topic")}
            className={`${FIELD} appearance-none`}
          >
            {CONTACT_TOPICS.map((topic) => (
              <option key={topic} value={topic} className="bg-surface text-ink">
                {topic}
              </option>
            ))}
          </select>
        </div>
        <div className="sm:col-span-2">
          <label className={LABEL} htmlFor="contact-message">
            Message
          </label>
          <textarea
            id="contact-message"
            required
            rows={5}
            value={form.message}
            onChange={set("message")}
            placeholder="Describe the issue, including your device model and app version if it's a bug."
            className={`${FIELD} resize-y`}
          />
        </div>
      </div>

      <div className="mt-7 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <Button type="submit" size="md">
          Send message
        </Button>
        <p className="text-xs text-ink-muted">
          Typical reply time: under 24 business hours.
        </p>
      </div>
    </form>
  );
}
