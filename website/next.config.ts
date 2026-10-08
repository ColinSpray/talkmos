import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  /* config options here */
  async headers() {
    return [
      {
        // Android App Links verification file — must serve as JSON for
        // the OS's verifier to accept it, and public/ would otherwise send
        // it with a generic octet-stream type since it has no extension.
        source: "/.well-known/assetlinks.json",
        headers: [{ key: "Content-Type", value: "application/json" }],
      },
      {
        // iOS Universal Links verification file — deliberately has no
        // extension (that's part of Apple's spec), so the content type has
        // to be set explicitly here rather than inferred from the filename.
        source: "/.well-known/apple-app-site-association",
        headers: [{ key: "Content-Type", value: "application/json" }],
      },
    ];
  },
};

export default nextConfig;
