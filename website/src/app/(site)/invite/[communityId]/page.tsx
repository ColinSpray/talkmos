import type { Metadata } from "next";
import OpenInApp from "@/components/site/OpenInApp";

export const metadata: Metadata = {
  title: "Community invite",
  robots: { index: false, follow: false },
};

export default async function InviteDeepLinkPage({
  params,
}: {
  params: Promise<{ communityId: string }>;
}) {
  const { communityId } = await params;
  return (
    <OpenInApp
      appUrl={`talkmos://invite/${communityId}`}
      title="You're invited to a community"
      subtitle="Open the invite in Talkmos to join the room and start talking."
    />
  );
}
