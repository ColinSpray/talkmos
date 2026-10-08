"use client";

import { useState } from "react";
import { MessagesTab } from "./MessagesTab";
import { StoriesTab } from "./StoriesTab";
import { ChatsTab } from "./ChatsTab";

const TABS = [
  { key: "messages", label: "Messages" },
  { key: "stories", label: "Stories" },
  { key: "chats", label: "Chats & Groups" },
] as const;

type TabKey = (typeof TABS)[number]["key"];

export default function ModerationPage() {
  const [tab, setTab] = useState<TabKey>("messages");
  const [openChatId, setOpenChatId] = useState<string | undefined>();

  return (
    <div>
      <h1 className="text-2xl font-semibold text-white">Moderation</h1>
      <p className="mt-1 text-sm text-slate-400">
        Browse and remove content across the platform.
      </p>

      <div className="mt-6 flex gap-2">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`rounded-xl px-4 py-2 text-sm font-medium transition ${
              tab === t.key
                ? "glass text-white"
                : "text-slate-400 hover:bg-white/5 hover:text-white"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="mt-6">
        {tab === "messages" && <MessagesTab initialChatId={openChatId} />}
        {tab === "stories" && <StoriesTab />}
        {tab === "chats" && (
          <ChatsTab
            onOpenChat={(chatId) => {
              setOpenChatId(chatId);
              setTab("messages");
            }}
          />
        )}
      </div>
    </div>
  );
}
