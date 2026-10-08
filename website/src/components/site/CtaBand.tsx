import { Container, ButtonLink } from "@/components/ui/primitives";
import PlayStoreButton from "./PlayStoreButton";
import ApkDownloadButton from "./ApkDownloadButton";
import Waveform from "./Waveform";

/** Closing call-to-action, repeated at the foot of every marketing page. */
export default function CtaBand({
  title = "Start talking in under a minute",
  description = "Free on Google Play, or straight from us as an APK. No credit card, no meeting links, no waiting room — just open a channel and speak.",
  secondary = { href: "/features", label: "Explore features" },
}: {
  title?: string;
  description?: string;
  secondary?: { href: string; label: string } | null;
}) {
  return (
    <section className="pb-8 pt-6">
      <Container>
        <div className="glass glass-outline relative overflow-hidden rounded-4xl px-6 py-14 text-center sm:px-12 sm:py-16">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute inset-x-0 -top-24 h-56 bg-linear-to-b from-brand-primary/25 to-transparent blur-3xl"
          />
          <div className="relative flex flex-col items-center gap-6">
            <Waveform bars={20} className="h-8 opacity-70" />
            <h2 className="max-w-xl text-3xl font-bold tracking-tight text-ink sm:text-4xl">
              {title}
            </h2>
            <p className="max-w-lg text-base leading-relaxed text-ink-soft">
              {description}
            </p>
            <div className="mt-2 flex flex-col items-center gap-3 sm:flex-row">
              <PlayStoreButton size="lg" />
              <ApkDownloadButton size="lg" />
            </div>
            {secondary && (
              <ButtonLink href={secondary.href} variant="glass" size="md">
                {secondary.label}
              </ButtonLink>
            )}
          </div>
        </div>
      </Container>
    </section>
  );
}
