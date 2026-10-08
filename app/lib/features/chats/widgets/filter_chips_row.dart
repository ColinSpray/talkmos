import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/recent_chat.dart';

/// Horizontal row of filter chips (All/Unread/Groups/...), each showing an
/// unread-activity dot when a chat in that category has unread messages.
class FilterChipsRow extends StatelessWidget {
  final bool isDark;
  final List<String> filters;
  final String selectedFilter;
  final List<RecentChat> allChats;
  final bool Function(String filterKey, RecentChat chat) matchesFilter;
  final ValueChanged<String> onFilterSelected;

  const FilterChipsRow({
    super.key,
    required this.isDark,
    required this.filters,
    required this.selectedFilter,
    required this.allChats,
    required this.matchesFilter,
    required this.onFilterSelected,
  });

  static String _filterLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'unread':
        return l10n.homeScreenFilterUnread;
      case 'groups':
        return l10n.homeScreenFilterGroups;
      case 'channels':
        return l10n.homeScreenFilterChannels;
      case 'bots':
        return l10n.homeScreenFilterBots;
      default:
        return l10n.homeScreenFilterAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((key) {
          final isSelected = selectedFilter == key;
          final hasUnread =
              key != 'all' &&
              allChats.any((c) => matchesFilter(key, c) && c.unreadCount > 0);

          final labelColor = isSelected
              ? Colors.white
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF000E23));

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onFilterSelected(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : (isDark
                            ? const Color(0xFF000814)
                            : const Color(0xFFF5F6F8)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filterLabel(l10n, key),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: 7),
                      // Turns white on the selected chip, which is otherwise
                      // filled with the same blue the dot uses.
                      _FilterChipDot(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Deliberately countless — signals "there's something here" without
/// competing with the per-chat unread counts in the list below.
class _FilterChipDot extends StatelessWidget {
  final Color color;

  const _FilterChipDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
