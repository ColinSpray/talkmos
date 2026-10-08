import { AuthProvider } from "./_lib/auth";

export const metadata = {
  title: "Talkmos Admin",
  description: "Admin panel for Talkmos",
};

export default function AdminRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Admin always stays dark regardless of the marketing site's light/dark
  // toggle — it's a control panel, not a themed page — hence the forced
  // `.dark` scope here rather than relying on the root <html> class.
  return (
    <div className="dark min-h-full bg-background text-foreground">
      <AuthProvider>{children}</AuthProvider>
    </div>
  );
}
