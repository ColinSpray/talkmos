import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/recent_chat.dart';
import '../../users/screens/user_search_screen.dart';
import 'recent_chat_tile.dart';

class RecentChatsList extends StatefulWidget {
  final bool isDark;
  final bool isLoading;
  final List<RecentChat> allChats;
  final List<RecentChat> filteredChats;
  final bool searching;
  final String searchText;
  final ValueChanged<RecentChat> onChatTap;
  final void Function(RecentChat chat, GlobalKey tileKey) onChatLongPress;

  const RecentChatsList({
    super.key,
    required this.isDark,
    required this.isLoading,
    required this.allChats,
    required this.filteredChats,
    required this.searching,
    required this.searchText,
    required this.onChatTap,
    required this.onChatLongPress,
  });

  @override
  State<RecentChatsList> createState() => _RecentChatsListState();
}

class _RecentChatsListState extends State<RecentChatsList> {
  final Map<String, GlobalKey> _chatTileKeys = {};

  @override
  Widget build(BuildContext context) {
    final liveChatIds = widget.allChats.map((c) => c.conversationId).toSet();
    _chatTileKeys.removeWhere((id, _) => !liveChatIds.contains(id));

    if (widget.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => _SkeletonChatTile(isDark: widget.isDark),
        ),
      );
    }

    if (widget.filteredChats.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.searching
                  ? Icons.search_off_rounded
                  : Icons.chat_bubble_outline_rounded,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.searching
                ? l10n.homeScreenNoChatsFound
                : l10n.homeScreenNoChatsYet,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white70 : const Color(0xFF000E23),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.searching
                ? l10n.homeScreenNoConversationsMatch(widget.searchText)
                : l10n.homeScreenEmptyStateHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          if (widget.searching) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              ),
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: Text(l10n.homeScreenSearchPeople),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.filteredChats.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 76,
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF1F5F9),
      ),
      itemBuilder: (_, index) {
        final chat = widget.filteredChats[index];
        final tileKey = _chatTileKeys.putIfAbsent(
          chat.conversationId,
          () => GlobalKey(),
        );
        return Container(
          key: tileKey,
          child: RecentChatTile(
            chat: chat,
            isDark: widget.isDark,
            onTap: () => widget.onChatTap(chat),
            onLongPress: () => widget.onChatLongPress(chat, tileKey),
          ),
        );
      },
    );
  }
}

class _SkeletonChatTile extends StatelessWidget {
  final bool isDark;
  const _SkeletonChatTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000814) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          const Bone.circle(size: 44),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 130, fontSize: 14),
                SizedBox(height: 6),
                Bone.text(width: 90, fontSize: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
