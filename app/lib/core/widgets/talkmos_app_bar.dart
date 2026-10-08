import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';

class TalkmosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showMenuButton;

  const TalkmosAppBar({super.key, this.actions, this.showMenuButton = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      leading: showMenuButton && !canPop
          ? null
          : canPop
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF000000),
                size: 20,
              ),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      titleSpacing: showMenuButton && !canPop ? 0 : null,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppLocalizations.of(context).commonAppName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.6,
                  color: isDark ? Colors.white : const Color(0xFF000000),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: actions != null ? [...actions!, const SizedBox(width: 8)] : null,
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class TalkmosAppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const TalkmosAppBarAction({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000814) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF000000),
          ),
        ),
      ),
    );
  }
}

class TalkmosNotificationAction extends StatelessWidget {
  final VoidCallback onTap;
  final int unreadCount;

  const TalkmosNotificationAction({
    super.key,
    required this.onTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF000814)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.notifications_rounded,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF000000)
                          : const Color(0xFFFAF9FF),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
