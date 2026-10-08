"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "./_lib/auth";
import { FullPageSpinner } from "./_components/Spinner";

export default function AdminIndex() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (loading) return;
    router.replace(user ? "/admin/dashboard" : "/admin/login");
  }, [loading, user, router]);

  return <FullPageSpinner />;
}
