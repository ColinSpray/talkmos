import type { Metadata } from "next";
import OpenInApp from "@/components/site/OpenInApp";

export const metadata: Metadata = {
  title: "Open chat",
  // Deep-link landings are per-user and worthless in search results.
  robots: { index: false, follow: false },
};

export default async function ChatDeepLinkPage({
  params,
}: {
  params: Promise<{ userId: string }>;
}) {
  const { userId } = await params;
  return (
    <OpenInApp
      appUrl={`talkmos://chat/${userId}`}
      title="Someone wants to chat with you"
      subtitle="This conversation lives in the Talkmos app. We're handing the link over now."
    />
  );
}
