export const APP_CONFIG = {
  name: "Talkmos",
  tagline: "Crystal Clear Voice Rooms & Push-To-Talk Communication",
  description:
    "Connect instantly with high-fidelity low-latency audio rooms, push-to-talk walkie-talkie mode, AI noise suppression, and end-to-end encrypted private voice channels.",
  url: "https://talkmos.com",
  developer: {
    name: "Talkmos Systems Inc.",
    email: "support@talkmos.com",
    privacyEmail: "privacy@talkmos.com",
    address: "Kolkata, West Bengal, India",
  },
  playStoreUrl: "https://play.google.com/store/apps/details?id=com.talkmos.app",
  apkDownloadUrl: "https://stage-api.talkmos.com/api/v1/apk/download",
  apkSize: "66 MB",
  packageName: "com.talkmos.app",
  appVersion: "2.4.0",
  lastUpdated: "July 28, 2026",
};

/** Primary header navigation. Kept short on purpose — everything else
 *  lives in the footer sitemap. */
export const NAV_LINKS = [
  { name: "Features", href: "/features" },
  { name: "Audio Tech", href: "/technology" },
  { name: "Download", href: "/download" },
  { name: "Support", href: "/contact" },
];

export const FOOTER_SECTIONS = [
  {
    title: "Product",
    links: [
      { name: "Features", href: "/features" },
      { name: "Audio Technology", href: "/technology" },
      { name: "Download for Android", href: "/download" },
    ],
  },
  {
    title: "Legal",
    links: [
      { name: "Privacy Policy", href: "/privacy" },
      { name: "Terms of Service", href: "/terms" },
      { name: "Cookie Policy", href: "/cookies" },
    ],
  },
  {
    title: "Account",
    links: [
      { name: "Support & Contact", href: "/contact" },
      { name: "Delete My Account", href: "/delete-account" },
      { name: "Frequently Asked", href: "/contact#faq" },
    ],
  },
];

/** Headline numbers used in the hero strip and on /technology. */
export const STATS = [
  { value: "<40ms", label: "End-to-end latency" },
  { value: "48kHz", label: "Full-band sample rate" },
  { value: "SRTP", label: "Encrypted transport" },
  { value: "12kbps", label: "Low-data mode floor" },
];

export type IconName =
  | "microphone"
  | "sparkles"
  | "walkieTalkie"
  | "shieldCheck"
  | "cpu"
  | "globe"
  | "waveform"
  | "bolt"
  | "users"
  | "lock"
  | "bell"
  | "battery";

export const FEATURES: {
  icon: IconName;
  title: string;
  description: string;
}[] = [
    {
      icon: "microphone",
      title: "HD Ultra-Low Latency Audio",
      description:
        "Powered by Opus spatial audio codecs delivering sub-40ms latency crystal-clear voice communication.",
    },
    {
      icon: "sparkles",
      title: "AI Neural Noise Cancellation",
      description:
        "Filter out background chatter, traffic, wind, and mechanical noise automatically in real-time.",
    },
    {
      icon: "walkieTalkie",
      title: "Push-To-Talk & Live Rooms",
      description:
        "Instant walkie-talkie channels for quick audio drops or persistent drop-in voice hangouts for groups.",
    },
    {
      icon: "shieldCheck",
      title: "End-to-End Privacy",
      description:
        "Encrypted audio pipelines built on WebRTC and SRTP standards. Your conversations belong solely to you.",
    },
    {
      icon: "cpu",
      title: "Battery & Data Efficient",
      description:
        "Optimized network bandwidth usage (under 12kbps in low-data mode) to conserve battery on all devices.",
    },
    {
      icon: "globe",
      title: "Cross-Platform Sync",
      description:
        "Seamlessly switch between Android app, mobile browser, and desktop web without dropping calls.",
    },
  ];

/** Longer-form feature copy for the dedicated /features page. */
export const FEATURE_DETAILS: {
  icon: IconName;
  eyebrow: string;
  title: string;
  description: string;
  points: string[];
}[] = [
    {
      icon: "walkieTalkie",
      eyebrow: "Talk instantly",
      title: "Push-to-talk that actually feels instant",
      description:
        "Hold the key, speak, release. The channel stays warm between transmissions so there is no connection handshake tax on every message.",
      points: [
        "Warm channels keep the socket alive between bursts",
        "Hardware button and Bluetooth headset trigger support",
        "Audio drops queue and deliver when a listener reconnects",
      ],
    },
    {
      icon: "users",
      eyebrow: "Stay together",
      title: "Drop-in rooms for groups that hang around",
      description:
        "Persistent voice rooms your community can wander into. No ringing, no scheduling, no meeting links — the room is simply open.",
      points: [
        "Roles and moderation controls for room owners",
        "Raise-hand queue for larger listening rooms",
        "Live speaker indicators driven by real audio energy",
      ],
    },
    {
      icon: "sparkles",
      eyebrow: "Sound better",
      title: "Neural noise suppression on device",
      description:
        "A compact on-device model separates speech from everything else, so keyboards, traffic and wind never make it into the channel.",
      points: [
        "Runs on device — audio is not shipped off for processing",
        "Automatic gain control keeps quiet talkers audible",
        "Echo cancellation tuned for speakerphone use",
      ],
    },
    {
      icon: "lock",
      eyebrow: "Stay private",
      title: "Encrypted by default, recorded by nobody",
      description:
        "Every session negotiates SRTP keys over DTLS. Live audio is relayed, never archived, unless a room owner explicitly turns recording on.",
      points: [
        "DTLS-SRTP encrypted media for every participant",
        "No ambient recording, ever — mic access is session-scoped",
        "Self-serve data export and deletion from inside the app",
      ],
    },
  ];

/** Technical spec rows for /technology. */
export const TECH_SPECS = [
  { label: "Codec", value: "Opus 1.5 (full-band)" },
  { label: "Sample rate", value: "48 kHz / 20 ms frames" },
  { label: "Transport", value: "WebRTC over UDP, TCP fallback" },
  { label: "Encryption", value: "DTLS-SRTP (AES-128-GCM)" },
  { label: "Bitrate range", value: "12 – 64 kbps adaptive" },
  { label: "Jitter buffer", value: "Adaptive, 20 – 120 ms" },
  { label: "Packet loss concealment", value: "Opus PLC + selective retransmit" },
  { label: "Echo control", value: "AEC3 with delay estimation" },
];

/** Latency comparison bars — value is ms, used for both label and width. */
export const LATENCY_COMPARISON = [
  { label: "Talkmos push-to-talk", ms: 38, highlight: true },
  { label: "Typical VoIP call", ms: 150, highlight: false },
  { label: "Live streaming relay", ms: 400, highlight: false },
];

export const PIPELINE_STAGES: { icon: IconName; title: string; description: string }[] = [
  {
    icon: "microphone",
    title: "Capture",
    description:
      "Audio is captured at 48 kHz in 20 ms frames, with automatic gain control applied before anything else touches the signal.",
  },
  {
    icon: "sparkles",
    title: "Clean",
    description:
      "Echo cancellation and the neural suppressor run on device, stripping room noise while leaving speech untouched.",
  },
  {
    icon: "cpu",
    title: "Encode",
    description:
      "Opus encodes the cleaned frames, adapting bitrate between 12 and 64 kbps as the network moves under you.",
  },
  {
    icon: "lock",
    title: "Deliver",
    description:
      "Frames travel DTLS-SRTP encrypted over WebRTC, with an adaptive jitter buffer smoothing playback on the far side.",
  },
];

export const STEPS = [
  {
    step: "01",
    title: "Download & sign up",
    description:
      "Grab Talkmos free from Google Play and create your account in under a minute — email or phone, nothing else needed.",
  },
  {
    step: "02",
    title: "Join or start a room",
    description:
      "Drop into a live voice room, or fire up push-to-talk for an instant one-tap conversation with anyone on your list.",
  },
  {
    step: "03",
    title: "Talk, instantly",
    description:
      "Sub-40ms audio, neural noise cancellation and encryption all run automatically in the background. Nothing to configure.",
  },
];

export const FAQS = [
  {
    question: "Is Talkmos free to download on Google Play?",
    answer:
      "Yes. Talkmos is completely free to download from the Google Play Store, with full access to standard voice rooms and push-to-talk features.",
  },
  {
    question: "How does Talkmos protect my voice and personal data?",
    answer:
      "We use industry-standard WebRTC DTLS-SRTP encryption. Audio is processed strictly in real time during live calls and is not permanently recorded or stored on our servers unless a channel owner explicitly enables recording.",
  },
  {
    question: "How can I request deletion of my Talkmos account and data?",
    answer:
      "You can request deletion inside the Android app under Settings > Account, or from our Data Deletion page at talkmos.com/delete-account. Deletion starts a 30-day grace period, after which everything is permanently purged.",
  },
  {
    question: "What permissions does Talkmos require on Android?",
    answer:
      "Microphone (RECORD_AUDIO) to capture audio while you speak, network state access to manage server connections, and optional Bluetooth access for wireless headsets. Microphone access is only active during a live session.",
  },
  {
    question: "Does Talkmos work on a poor mobile connection?",
    answer:
      "Yes. The encoder adapts down to roughly 12 kbps in low-data mode, and packet loss concealment fills short gaps so speech stays intelligible on weak networks.",
  },
  {
    question: "Can I use Talkmos with a Bluetooth headset or in the car?",
    answer:
      "Yes. Talkmos routes audio to connected Bluetooth devices and supports headset media buttons as a push-to-talk trigger, which makes it practical for driving and hands-free use.",
  },
];

export const CONTACT_TOPICS = [
  "General support",
  "Technical / audio issue",
  "Account & billing",
  "Privacy request",
  "Report abuse",
  "Press & partnerships",
];

export const DELETION_REASONS = [
  "I no longer use the app",
  "Privacy concerns",
  "Found an alternative",
  "Too many notifications",
  "Audio quality issues",
  "Other",
];
