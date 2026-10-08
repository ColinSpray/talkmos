import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  {
    // The admin section is a client-rendered SPA-style panel that fetches
    // from a separate REST API on mount/page-change — the canonical
    // setLoading(true)-then-fetch effect body. That's exactly what this
    // rule flags, so it fires on every data-fetching page there. Scoped to
    // admin/ only — the marketing site has no similar pattern.
    files: ["src/app/admin/**/*.{ts,tsx}"],
    rules: {
      "react-hooks/set-state-in-effect": "off",
    },
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
]);

export default eslintConfig;
