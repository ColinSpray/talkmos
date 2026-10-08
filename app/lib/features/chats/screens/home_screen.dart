import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/user_model.dart';
import '../../../providers/providers.dart';
import '../../../models/recent_chat.dart';
import '../widgets/archived_chats_row.dart';
import '../widgets/chats_search_bar.dart';
import '../widgets/context_action_menu.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/recent_chat_tile.dart';
import '../widgets/recent_chats_list.dart';
import '../widgets/stories_row.dart';
import 'archived_chats_screen.dart';
import 'chat_screen/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 'all' | 'direct' | 'group'
  String _selectedFilter = 'all';

  static const List<String> _filters = [
    'all',
    'unread',
    'groups',
    'channels',
    'bots',
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<ChatProvider>().loadRecentChats();
        context.read<ChatProvider>().loadArchivedChats();
        context.read<StoryProvider>().loadStoriesFeed();
        context.read<BlockProvider>().loadBlockedUsers();
      }
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      await Future.wait([
        context.read<ChatProvider>().loadRecentChats(force: true),
        context.read<ChatProvider>().loadArchivedChats(force: true),
        context.read<StoryProvider>().loadStoriesFeed(),
        // Included so a block made on another device shows up on pull-to-refresh
        // instead of only after a restart — initState is the sole other loader.
        context.read<BlockProvider>().loadBlockedUsers(),
      ]);
    }
  }

  void _handleChatLongPress(RecentChat chat, GlobalKey tileKey, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final box = tileKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final tileRect = box.localToGlobal(Offset.zero) & box.size;
    final chatProvider = context.read<ChatProvider>();
    final isGroupLike = chat.chatType != 'direct';
    final peer = chat.peerFor(chatProvider.user?.id);
    final isPeerBlocked =
        peer != null && context.read<BlockProvider>().isBlocked(peer.id);

    ContextActionMenu.show(
      context: context,
      anchor: RecentChatTile(chat: chat, isDark: isDark, onTap: () {}),
      anchorRect: tileRect,
      alignEnd: false,
      isDark: isDark,
      actionGroups: [
        [
          ContextActionItem(
            icon: chat.isPinned
                ? Icons.push_pin_outlined
                : Icons.push_pin_rounded,
            label: chat.isPinned
                ? l10n.homeScreenUnpinChat
                : l10n.homeScreenPinChat,
            onTap: () => chatProvider.togglePinChat(chat),
          ),
          ContextActionItem(
            icon: chat.isMuted
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: chat.isMuted
                ? l10n.commonUnmute
                : l10n.homeScreenMuteNotifications,
            onTap: () => chatProvider.toggleMuteChat(chat),
          ),
          ContextActionItem(
            icon: chat.isArchived
                ? Icons.unarchive_rounded
                : Icons.archive_outlined,
            label: chat.isArchived
                ? l10n.homeScreenUnarchiveChat
                : l10n.homeScreenArchiveChat,
            onTap: () => chatProvider.toggleArchiveChat(chat),
          ),
        ],
        [
          if (isGroupLike)
            ContextActionItem(
              icon: Icons.exit_to_app_rounded,
              label: l10n.homeScreenLeaveGroup,
              isDestructive: true,
              onTap: () => _confirmLeaveGroup(chat),
            ),
          if (!isGroupLike)
            ContextActionItem(
              icon: isPeerBlocked
                  ? Icons.check_circle_outline_rounded
                  : Icons.block_rounded,
              label: isPeerBlocked
                  ? l10n.homeScreenUnblockContact
                  : l10n.homeScreenBlockContact,
              isDestructive: !isPeerBlocked,
              onTap: () => _toggleBlockFromChat(chat, isPeerBlocked),
            ),
        ],
        [
          ContextActionItem(
            icon: Icons.delete_outline_rounded,
            label: l10n.homeScreenDeleteChat,
            isDestructive: true,
            onTap: () => _confirmDeleteChat(chat),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleBlockFromChat(RecentChat chat, bool isBlocked) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final blockProvider = context.read<BlockProvider>();
    final peer = chat.peerFor(context.read<ChatProvider>().user?.id);

    // Direct chats the server sent without member details leave nobody to
    // block. Say so rather than silently doing nothing, as this used to.
    if (peer == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.homeScreenContactNotIdentified),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final name = toTitleCase(peer.name.isEmpty ? chat.title : peer.name);
    if (!isBlocked) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.homeScreenBlockConfirmTitle(name)),
          content: Text(l10n.homeScreenBlockConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text(l10n.commonBlock),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      if (isBlocked) {
        await blockProvider.unblockUser(peer.id);
      } else {
        await blockProvider.blockUser(
          UserModel(id: peer.id, name: peer.name, avatarUrl: peer.imageUrl),
        );
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isBlocked
                ? l10n.homeScreenContactUnblocked(name)
                : l10n.homeScreenContactBlocked(name),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.homeScreenBlockStatusUpdateFailed(e.toString())),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteChat(RecentChat chat) async {
    final l10n = AppLocalizations.of(context);
    final chatProvider = context.read<ChatProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homeScreenDeleteChat),
        content: Text(l10n.homeScreenDeleteChatBody(toTitleCase(chat.title))),
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
        title: Text(l10n.homeScreenLeaveGroup),
        content: Text(l10n.homeScreenLeaveGroupBody(toTitleCase(chat.title))),
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
            content: Text(l10n.homeScreenLeaveGroupFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatState = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      appBar: HomeAppBar(
        isDark: isDark,
        // onMenuTap: () => Scaffold.of(context).openDrawer(),
      ),
      // Tapping anywhere outside the search field (a chat, the list, empty
      // space) dismisses the keyboard / search focus.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pinned outside the scroll view so it stays put — everything
              // below it scrolls, this doesn't.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: ChatsSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  isDark: isDark,
                  showClear: _searchQuery.isNotEmpty,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim().toLowerCase()),
                  onClear: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: Theme.of(context).primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StoriesRow(isDark: isDark),
                        const SizedBox(height: 14),
                        FilterChipsRow(
                          isDark: isDark,
                          filters: _filters,
                          selectedFilter: _selectedFilter,
                          allChats: chatState.recentChats,
                          matchesFilter: _matchesFilter,
                          onFilterSelected: (key) =>
                              setState(() => _selectedFilter = key),
                        ),
                        const SizedBox(height: 12),
                        ArchivedChatsRow(
                          isDark: isDark,
                          archivedCount: chatState.archivedChats.length,
                          unreadCount: chatState.archivedUnreadCount,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ArchivedChatsScreen(),
                              ),
                            ).then((_) => _loadData());
                          },
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity.abs() < 200) return;
                            _cycleFilter(velocity < 0 ? 1 : -1);
                          },
                          child: RecentChatsList(
                            isDark: isDark,
                            isLoading: chatState.isLoadingChats,
                            allChats: chatState.recentChats,
                            filteredChats: _filteredChats(
                              chatState.recentChats,
                            ),
                            searching: _searchQuery.isNotEmpty,
                            searchText: _searchController.text.trim(),
                            onChatTap: (chat) {
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
                              ).then((_) => _loadData());
                            },
                            onChatLongPress: (chat, tileKey) =>
                                _handleChatLongPress(chat, tileKey, isDark),
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleFilter(int direction) {
    final keys = _filters;
    final currentIndex = keys.indexOf(_selectedFilter);
    final nextIndex = (currentIndex + direction) % keys.length;
    setState(() => _selectedFilter = keys[nextIndex]);
  }

  /// Membership test for a filter key, shared by the chip badges and the list
  /// itself so a badge can never disagree with what tapping it shows.
  static bool _matchesFilter(String filterKey, RecentChat chat) {
    switch (filterKey) {
      case 'unread':
        return chat.unreadCount > 0;
      case 'groups':
        return chat.chatType == 'group' || chat.chatType == 'community';
      case 'channels':
        return chat.chatType == 'channel' || chat.chatType == 'official';
      case 'bots':
        return chat.chatType == 'bot';
      default:
        return true;
    }
  }

  List<RecentChat> _filteredChats(List<RecentChat> chats) {
    var result = chats;
    switch (_selectedFilter) {
      case 'unread':
        result = result.where((c) => c.unreadCount > 0).toList();
        break;
      case 'groups':
        result = result
            .where((c) => c.chatType == 'group' || c.chatType == 'community')
            .toList();
        break;
      case 'channels':
        result = result
            .where((c) => c.chatType == 'channel' || c.chatType == 'official')
            .toList();
        break;
      case 'bots':
        result = result.where((c) => c.chatType == 'bot').toList();
        break;
    }

    // Live text search over the chat title.
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((c) => c.title.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return result;
  }
}
