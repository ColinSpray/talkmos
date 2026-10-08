export interface AdminUser {
  _id: string;
  name?: string;
  username?: string;
  email?: string;
  phone?: string;
  avatarUrl?: string;
  role: "user" | "admin";
  isPremium: boolean;
  isVerified: boolean;
  premiumExpiry?: string | null;
  authProvider?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface Pagination {
  total: number;
  page: number;
  pages: number;
}

export interface Paginated<T> {
  data: T[];
  pagination: Pagination;
}

export interface Stats {
  users: {
    total: number;
    premium: number;
    verified: number;
    admin: number;
  };
  stats: {
    messages: number;
    chats: number;
    calls: number;
  };
}

export interface SystemSettings {
  _id: string;
  allowNewRegistrations: boolean;
  maintenanceMode: boolean;
  allowedEmailDomains: string[];
  latestVersionName: string;
  latestVersionCode: number;
  minRequiredVersionCode: number;
  releaseNotes: string;
  isForceUpdate: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface AuditLogEntry {
  _id: string;
  adminId?: { _id: string; name?: string; email?: string; phone?: string } | null;
  adminEmail?: string;
  method: string;
  path: string;
  statusCode: number;
  ipAddress?: string;
  createdAt: string;
}

interface RefShort {
  _id: string;
  name?: string;
  email?: string;
  phone?: string;
}

export interface ChatSummary {
  _id: string;
  chatType: "direct" | "group" | "community";
  sender?: RefShort | null;
  receiver?: RefShort | null;
  spaceId?: { _id: string; name?: string; imageUrl?: string } | null;
  createdAt: string;
  deletedAt?: string | null;
}

export interface AdminMessage {
  _id: string;
  chatId: string;
  senderId?: RefShort | null;
  messageType: string;
  content: string;
  createdAt: string;
  deletedForEveryone: boolean;
}

export interface AdminStory {
  _id: string;
  userId?: RefShort | null;
  mediaUrl: string;
  mediaType: "image" | "video";
  caption?: string;
  category?: string;
  visibility: "public" | "friends";
  expiresAt: string;
  createdAt: string;
}
