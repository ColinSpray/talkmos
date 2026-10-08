import Navbar from "@/components/site/Navbar";
import Footer from "@/components/site/Footer";

/**
 * Public marketing shell. The aurora + grain layers sit behind everything
 * at negative z-index and are rendered once here rather than per page, so
 * they persist across navigations without re-animating.
 */
export default function SiteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="relative flex min-h-full flex-col text-ink">
      <div className="aurora" aria-hidden="true" />
      <div className="grain" aria-hidden="true" />
      <Navbar />
      <main className="flex flex-1 flex-col">{children}</main>
      <Footer />
    </div>
  );
}
