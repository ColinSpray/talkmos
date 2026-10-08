import type { MetadataRoute } from "next";
import { APP_CONFIG } from "@/lib/constants";

/** Only the public marketing routes belong here — /admin is private and the
 *  deep-link landings are per-resource and marked noindex. */
const ROUTES: { path: string; priority: number; changeFrequency: "monthly" | "yearly" }[] = [
  { path: "", priority: 1, changeFrequency: "monthly" },
  { path: "/features", priority: 0.9, changeFrequency: "monthly" },
  { path: "/technology", priority: 0.8, changeFrequency: "monthly" },
  { path: "/download", priority: 0.9, changeFrequency: "monthly" },
  { path: "/contact", priority: 0.7, changeFrequency: "monthly" },
  { path: "/delete-account", priority: 0.7, changeFrequency: "yearly" },
  { path: "/privacy", priority: 0.6, changeFrequency: "yearly" },
  { path: "/terms", priority: 0.5, changeFrequency: "yearly" },
  { path: "/cookies", priority: 0.4, changeFrequency: "yearly" },
];

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date(APP_CONFIG.lastUpdated);

  return ROUTES.map((route) => ({
    url: `${APP_CONFIG.url}${route.path}`,
    lastModified,
    changeFrequency: route.changeFrequency,
    priority: route.priority,
  }));
}
