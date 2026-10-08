"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "../_lib/auth";
import { Button } from "./Button";

const NAV_ITEMS = [
  { href: "/admin/dashboard", label: "Dashboard", icon: "▦" },
  { href: "/admin/users", label: "Users", icon: "▤" },
  { href: "/admin/moderation", label: "Moderation", icon: "■" },
  { href: "/admin/notifications", label: "Notifications", icon: "◆" },
  { href: "/admin/settings", label: "Settings & Releases", icon: "⚙" },
  { href: "/admin/logs", label: "Logs", icon: "≡" },
  { href: "/admin/audit-log", label: "Audit Log", icon: "☷" },
];

export function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();

  return (
    <aside className="glass-panel sticky top-0 flex h-screen w-64 shrink-0 flex-col rounded-r-2xl p-5">
      <div className="mb-8">
        <p className="text-lg font-semibold text-white">Talkmos Admin</p>
        <p className="text-xs text-slate-400">Control center</p>
      </div>

      <nav className="flex flex-1 flex-col gap-1">
        {NAV_ITEMS.map((item) => {
          const active = pathname?.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition ${
                active
                  ? "glass text-white"
                  : "text-slate-300 hover:bg-white/5 hover:text-white"
              }`}
            >
              <span className="text-base opacity-80">{item.icon}</span>
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="glass mt-4 rounded-xl p-3">
        <p className="truncate text-sm font-medium text-white">
          {user?.name || user?.email || user?.phone}
        </p>
        <p className="truncate text-xs text-slate-400">{user?.email}</p>
        <Button
          variant="ghost"
          className="mt-3 w-full justify-center py-1.5"
          onClick={logout}
        >
          Log out
        </Button>
      </div>
    </aside>
  );
}
