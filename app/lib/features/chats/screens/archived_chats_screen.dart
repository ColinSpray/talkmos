import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/user_model.dart';
import '../../../providers/providers.dart';
import '../../../models/recent_chat.dart';
import '../widgets/context_action_menu.dart';
import '../widgets/recent_chat_tile.dart';
import 'chat_screen/chat_screen.dart';

/// WhatsApp-style archived chats list. Archived conversations are excluded
/// from the main chat list and live here until unarchived.
class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  final Map<String, GlobalKey> _tileKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadArchivedChats(force: true);
    });
  }

  Future<void> _refresh() =>
      context.read<ChatProvider>().loadArchivedChats(force: true);

  void _handleLongPress(RecentChat chat, GlobalKey tileKey, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final box = tileKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final tileRect = box.localToGlobal(Offset.zero) & box.size;
    final chatProvider = context.read<ChatProvider>();
    final isGroupLike = chat.chatType != 'direct';

    ContextActionMenu.show(
      context: context,
      anchor: RecentChatTile(chat: chat, isDark: isDark, onTap: () {}),
      anchorRect: tileRect,
      alignEnd: false,
      isDark: isDark,
      actionGroups: [
        [
          ContextActionItem(
            icon: Icons.unarchive_rounded,
            label: l10n.archivedChatsScreenUnarchiveChat,
            onTap: () => chatProvider.toggleArchiveChat(chat),
          ),
          ContextActionItem(
            icon: chat.isMuted
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: chat.isMuted
                ? l10n.commonUnmute
                : l10n.archivedChatsScreenMuteNotifications,
            onTap: () => chatProvider.toggleMuteChat(chat),
          ),
        ],
        [
          if (isGroupLike)
            ContextActionItem(
              icon: Icons.exit_to_app_rounded,
              label: l10n.archivedChatsScreenLeaveGroup,
              isDestructive: true,
              onTap: () => _confirmLeaveGroup(chat),
            ),
        ],
        [
          ContextActionItem(
            icon: Icons.delete_outline_rounded,
            label: l10n.archivedChatsScreenDeleteChat,
            isDestructive: true,
            onTap: () => _confirmDeleteChat(chat),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeleteChat(RecentChat chat) async {
    final l10n = AppLocalizations.of(context);
    final chatProvider = context.read<ChatProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.archivedChatsScreenDeleteChat),
        content: Text(
          l10n.archivedChatsScreenDeleteChatBody(toTitleCase(chat.title)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await chatProvider.deleteChat(chat);
    }
  }

  Future<void> _confirmLeaveGroup(RecentChat chat) async {
    final l10n = AppLocalizations.of(context);
    final chatProvider = context.read<ChatProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.archivedChatsScreenLeaveGroup),
        content: Text(
          l10n.archivedChatsScreenLeaveGroupBody(toTitleCase(chat.title)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.commonLeave),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await chatProvider.leaveGroupChat(chat);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.archivedChatsScreenLeaveGroupFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = context.watch<ChatProvider>();
    final chats = chatState.archivedChats;

    final liveIds = chats.map((c) => c.conversationId).toSet();
    _tileKeys.removeWhere((id, _) => !liveIds.contains(id));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF000000),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.archivedChatsScreenTitle,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF000000),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: Theme.of(context).primaryColor,
          child: chatState.isLoadingArchivedChats && chats.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : chats.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 76,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (_, index) {
                    final chat = chats[index];
                    final tileKey = _tileKeys.putIfAbsent(
                      chat.conversationId,
                      () => GlobalKey(),
                    );
                    return Container(
                      key: tileKey,
                      child: RecentChatTile(
                        chat: chat,
                        isDark: isDark,
                        onTap: () {
                          final peer = chat.peerFor(
                            context.read<ChatProvider>().user?.id,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat.conversationId,
                                chatType: chat.chatType,
                                activeUser: UserModel(
                                  id: peer?.id ?? '',
                                  name: peer?.name ?? chat.title,
                                  avatarUrl:
                                      (peer?.imageUrl.isNotEmpty ?? false)
                                      ? peer!.imageUrl
                                      : chat.avatarUrl,
                                ),
                              ),
                            ),
                          );
                        },
                        onLongPress: () =>
                            _handleLongPress(chat, tileKey, isDark),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context);
    // Wrapped in a scroll view so pull-to-refresh still works when empty.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.archive_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.archivedChatsScreenEmptyTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF000E23),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.archivedChatsScreenEmptyBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
