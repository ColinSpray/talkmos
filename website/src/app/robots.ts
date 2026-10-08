import type { MetadataRoute } from "next";
import { APP_CONFIG } from "@/lib/constants";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      // The admin panel and the per-resource deep-link landings have
      // nothing worth indexing.
      disallow: ["/admin", "/api/", "/chat/", "/invite/", "/story/"],
    },
    sitemap: `${APP_CONFIG.url}/sitemap.xml`,
  };
}
