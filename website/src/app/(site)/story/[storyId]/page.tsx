import type { Metadata } from "next";
import OpenInApp from "@/components/site/OpenInApp";

export const metadata: Metadata = {
  title: "Open story",
  robots: { index: false, follow: false },
};

export default async function StoryDeepLinkPage({
  params,
}: {
  params: Promise<{ storyId: string }>;
}) {
  const { storyId } = await params;
  return (
    <OpenInApp
      appUrl={`talkmos://story/${storyId}`}
      title="Someone shared a story with you"
      subtitle="Stories play inside the Talkmos app. We're opening it for you now."
    />
  );
}
