"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { useRouter } from "next/navigation";
import { api, apiErrorMessage, TOKEN_KEY } from "./api";
import type { AdminUser } from "./types";

const USER_KEY = "talkmos_admin_user";

interface AuthContextValue {
  user: AdminUser | null;
  loading: boolean;
  login: (identifier: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const stored = localStorage.getItem(USER_KEY);
    const token = localStorage.getItem(TOKEN_KEY);
    if (stored && token) {
      setUser(JSON.parse(stored));
    }
    setLoading(false);
  }, []);

  const login = useCallback(async (identifier: string, password: string) => {
    const isEmail = identifier.includes("@");
    const { data } = await api.post("/auth/login", {
      [isEmail ? "email" : "username"]: identifier,
      password,
    });

    if (!data.success || !data.token) {
      throw new Error(data.message ?? "Login failed");
    }

    // Login JWTs don't carry role, and this account's role isn't in the
    // login response either — so the only authoritative way to know this
    // user is an admin is to ask an admin-only route with the fresh token.
    localStorage.setItem(TOKEN_KEY, data.token);
    try {
      const stats = await api.get("/admin/stats");
      if (!stats.data.success) throw new Error("Not authorized");
    } catch (err) {
      localStorage.removeItem(TOKEN_KEY);
      throw new Error(
        apiErrorMessage(err, "This account does not have admin privileges"),
      );
    }

    const adminUser: AdminUser = { ...data.user, role: "admin" };
    localStorage.setItem(USER_KEY, JSON.stringify(adminUser));
    setUser(adminUser);
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}

export function useRequireAuth() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.replace("/admin/login");
    }
  }, [loading, user, router]);

  return { user, loading };
}
