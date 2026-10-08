import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { APP_CONFIG } from "@/lib/constants";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
  display: "swap",
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(APP_CONFIG.url),
  title: {
    default: `${APP_CONFIG.name} — ${APP_CONFIG.tagline}`,
    template: `%s | ${APP_CONFIG.name}`,
  },
  description: APP_CONFIG.description,
  applicationName: APP_CONFIG.name,
  keywords: [
    "Talkmos",
    "voice chat app",
    "push to talk",
    "walkie talkie app",
    "realtime audio",
    "audio rooms",
    "low latency voice",
    "Android voice chat",
  ],
  authors: [{ name: APP_CONFIG.developer.name }],
  creator: APP_CONFIG.developer.name,
  publisher: APP_CONFIG.developer.name,
  openGraph: {
    title: `${APP_CONFIG.name} — ${APP_CONFIG.tagline}`,
    description: APP_CONFIG.description,
    url: APP_CONFIG.url,
    siteName: APP_CONFIG.name,
    images: [{ url: "/logo.png", width: 1024, height: 1024, alt: APP_CONFIG.name }],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: APP_CONFIG.name,
    description: APP_CONFIG.description,
    images: ["/logo.png"],
  },
  alternates: { canonical: "/" },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  // Follows the resolved theme so the mobile browser chrome matches the
  // page rather than flashing a stale colour on scroll.
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f6f8fc" },
    { media: "(prefers-color-scheme: dark)", color: "#04060d" },
  ],
  colorScheme: "light dark",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <head>
        {/* Runs before paint so the site never flashes the wrong theme:
            respects a saved preference, otherwise falls back to the
            visitor's OS setting. The admin section always forces dark
            regardless of this, via its own layout.

            It also marks the document as scripted, which is what arms the
            scroll-reveal animations — without it every `.reveal` element
            renders immediately instead of waiting on an observer that will
            never run. */}
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){var e=document.documentElement;e.classList.add('js');try{var t=localStorage.getItem('theme');var d=t?t==='dark':window.matchMedia('(prefers-color-scheme: dark)').matches;if(d)e.classList.add('dark');}catch(x){}})();`,
          }}
        />
      </head>
      <body className="flex min-h-full flex-col">{children}</body>
    </html>
  );
}
