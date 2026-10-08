"use client";

import { useRequireAuth } from "../_lib/auth";
import { Sidebar } from "../_components/Sidebar";
import { FullPageSpinner } from "../_components/Spinner";

export default function ProtectedAdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user, loading } = useRequireAuth();

  if (loading || !user) {
    return <FullPageSpinner />;
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <div className="mx-auto max-w-6xl space-y-6">{children}</div>
      </main>
    </div>
  );
}
