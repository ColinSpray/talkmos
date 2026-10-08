import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class ContextActionItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;
  final List<ContextActionItem>? subItems;

  const ContextActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
    this.trailing,
    this.subItems,
  }) : assert(
         (onTap == null) != (subItems == null),
         'Provide exactly one of onTap or subItems',
       );
}

class ContextActionMenu {
  static const List<String> quickEmojis = ['❤️', '😂', '👍', '😮', '😢', '🙏'];

  static Future<void> show({
    required BuildContext context,
    required Widget anchor,
    required Rect anchorRect,
    required bool alignEnd,
    required bool isDark,
    void Function(String emoji)? onReact,
    VoidCallback? onMoreReactions,
    required List<List<ContextActionItem>> actionGroups,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context).contextActionMenuActionsLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _MenuOverlay(
          anchor: anchor,
          anchorRect: anchorRect,
          alignEnd: alignEnd,
          isDark: isDark,
          onReact: onReact,
          onMoreReactions: onMoreReactions,
          actionGroups: actionGroups,
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(curved),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}

/// Least vertical room the anchored layout needs beside the bubble. Below it
/// the fitted layout takes over, which can never put the card off-screen.
const double _minAnchoredSpace = 170;

class _MenuOverlay extends StatelessWidget {
  final Widget anchor;
  final Rect anchorRect;
  final bool alignEnd;
  final bool isDark;
  final void Function(String emoji)? onReact;
  final VoidCallback? onMoreReactions;
  final List<List<ContextActionItem>> actionGroups;

  const _MenuOverlay({
    required this.anchor,
    required this.anchorRect,
    required this.alignEnd,
    required this.isDark,
    required this.onReact,
    required this.onMoreReactions,
    required this.actionGroups,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final topSafe = media.padding.top + 12;
    final bottomSafe = media.padding.bottom + 12;

    final spaceAbove = anchorRect.top - topSafe;
    final spaceBelow = screen.height - bottomSafe - anchorRect.bottom;

    // A bubble taller than the viewport runs off both edges, so neither edge
    // is a real place to hang the card off — that is the fitted layout's job.
    final anchored =
        spaceAbove >= 0 &&
        spaceBelow >= 0 &&
        math.max(spaceAbove, spaceBelow) >= _minAnchoredSpace;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
        ),
        if (anchored)
          ..._anchoredLayout(context, screen, spaceAbove, spaceBelow)
        else
          _fittedLayout(context, screen, topSafe, bottomSafe),
      ],
    );
  }

  /// The bubble stays exactly where it sits in the list and the card hangs off
  /// whichever edge has more room.
  List<Widget> _anchoredLayout(
    BuildContext context,
    Size screen,
    double spaceAbove,
    double spaceBelow,
  ) {
    final showBelow = spaceBelow >= spaceAbove;
    return [
      Positioned(
        top: anchorRect.top,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Material(color: Colors.transparent, child: anchor),
        ),
      ),
      Positioned(
        left: alignEnd ? null : 16,
        right: alignEnd ? 16 : null,
        top: showBelow ? anchorRect.bottom + 10 : null,
        bottom: showBelow ? null : (screen.height - anchorRect.top + 10),
        child: _menu(
          context,
          screen,
          (showBelow ? spaceBelow : spaceAbove) - 10,
        ),
      ),
    ];
  }

  /// For a bubble too tall to anchor to: the preview shrinks to whatever the
  /// card leaves over and scrolls, so both always land inside the viewport.
  Widget _fittedLayout(
    BuildContext context,
    Size screen,
    double topSafe,
    double bottomSafe,
  ) {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(top: topSafe, bottom: bottomSafe),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SingleChildScrollView(
                  child: IgnorePointer(
                    child: Material(color: Colors.transparent, child: anchor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _menu(context, screen, screen.height * 0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, Size screen, double maxHeight) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: screen.width - 32,
        maxHeight: math.max(maxHeight, 120),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReact != null) ...[
              _ReactionBar(
                isDark: isDark,
                onReact: (emoji) {
                  Navigator.of(context).pop();
                  onReact!(emoji);
                },
                onMore: () {
                  Navigator.of(context).pop();
                  onMoreReactions?.call();
                },
              ),
              const SizedBox(height: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screen.width * 0.74),
              child: _ActionCard(
                isDark: isDark,
                groups: actionGroups,
                onTapItem: (cb) {
                  Navigator.of(context).pop();
                  cb();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  final bool isDark;
  final void Function(String emoji) onReact;
  final VoidCallback onMore;

  const _ReactionBar({
    required this.isDark,
    required this.onReact,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000814) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in ContextActionMenu.quickEmojis)
              GestureDetector(
                onTap: () => onReact(emoji),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 24,
                      decoration: TextDecoration.none,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: onMore,
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final bool isDark;
  final List<List<ContextActionItem>> groups;
  final void Function(VoidCallback onTap) onTapItem;

  const _ActionCard({
    required this.isDark,
    required this.groups,
    required this.onTapItem,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  /// Non-null while showing a row's [ContextActionItem.subItems] in place of
  /// the top-level groups — e.g. after tapping "Translate".
  List<ContextActionItem>? _subItems;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF000E23);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000814) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _subItems == null
                ? _buildList(
                    key: const ValueKey('main'),
                    groups: widget.groups.where((g) => g.isNotEmpty).toList(),
                    textColor: textColor,
                    iconColor: iconColor,
                    dividerColor: dividerColor,
                  )
                : _buildList(
                    key: const ValueKey('sub'),
                    groups: [_subItems!],
                    textColor: textColor,
                    iconColor: iconColor,
                    dividerColor: dividerColor,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildList({
    required Key key,
    required List<List<ContextActionItem>> groups,
    required Color textColor,
    required Color iconColor,
    required Color dividerColor,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int g = 0; g < groups.length; g++) ...[
          if (g > 0) Divider(height: 1, thickness: 1, color: dividerColor),
          for (final item in groups[g])
            InkWell(
              onTap: () {
                if (item.subItems != null) {
                  setState(() => _subItems = item.subItems);
                } else {
                  widget.onTapItem(item.onTap!);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: item.isDestructive ? Colors.redAccent : iconColor,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: item.isDestructive
                              ? Colors.redAccent
                              : textColor,
                        ),
                      ),
                    ),
                    if (item.trailing != null) item.trailing!,
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
