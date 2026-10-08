# Talkmos — website

Marketing site and admin panel for the Talkmos voice-chat app, built with
Next.js 16 (App Router, Turbopack) and Tailwind CSS v4.

## Getting started

```bash
npm install
npm run dev      # http://localhost:3000
```

Copy `.env.example` to `.env.local` and fill in the values before running the
admin panel; the marketing pages need no configuration.

```bash
npm run build    # production build (standalone output)
npm run start    # serve the build
npm run lint     # eslint
```

## Layout

```
src/app/
  layout.tsx           root layout — fonts, metadata, theme bootstrap script
  globals.css          design tokens, glass primitives, animations
  (site)/              public marketing site
    page.tsx           home
    features/          product tour
    technology/        audio pipeline & specs
    download/          Play Store landing, permissions, requirements
    contact/           support form + FAQ
    delete-account/    Google Play data-deletion flow
    privacy|terms|cookies/
    chat|invite|story/ app-link landings (noindex)
  admin/               staff control panel (forces dark, own layout)
  api/delete-account/  soft-delete endpoint
src/components/
  site/                site-specific components (nav, footer, forms, mockup)
  ui/                  reusable primitives (Container, GlassCard, Reveal, …)
src/lib/constants.ts   all site copy and configuration
```

## Design system

Everything visual is driven by CSS custom properties in
[`src/app/globals.css`](src/app/globals.css):

- **Tokens** — brand colours come from the Flutter app's `app_theme.dart` and
  stay fixed across themes. Surface, ink and glass tokens flip between the
  `:root` (light) and `.dark` blocks.
- **Glass primitives** — `.glass`, `.glass-panel`, `.glass-card`,
  `.glass-input`, `.glass-outline`. All read the same `--glass-*` knobs, so
  retuning the recipe re-tints every surface at once. The admin panel uses
  these too; keep the class names stable.
- **Backdrop** — `.aurora` and `.grain` are fixed, pointer-events-none layers
  rendered once in the `(site)` layout.
- **Motion** — scroll reveals are gated on a `.js` class added by the inline
  head script, so content renders normally without JavaScript, and the whole
  system collapses under `prefers-reduced-motion`.

## Theming

Theme is class-based (`.dark` on `<html>`), stored in `localStorage` under
`theme`, and applied by a blocking inline script in the root layout so there is
no flash of the wrong theme. `/admin` forces dark regardless.

## Assets

The app icon is copied from the Flutter project
(`assets/images/logo.png`) into `public/logo.png` plus the Next.js icon
conventions (`src/app/icon.png`, `apple-icon.png`, `favicon.ico`). Regenerate
those together whenever the app's logo changes.
