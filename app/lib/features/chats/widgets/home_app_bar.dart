import 'package:flutter/material.dart';
import '../../../providers/providers.dart';
import '../../nearby/screens/nearby_screen.dart';
import '../../stories/screens/create_story_screen.dart';
import '../../users/screens/friend_requests_screen.dart';

/// Home screen's top bar: title, pending-friend-request bell, Nearby, and a
/// shortcut into the story composer.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  // final VoidCallback onMenuTap;

  const HomeAppBar({
    super.key,
    required this.isDark, // required this.onMenuTap
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context);
    final iconColor = isDark ? Colors.white : const Color(0xFF000000);

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: null,
      title: Text(
        "TalkMos",
        style: TextStyle(
          color: iconColor,
          fontWeight: FontWeight.bold,
          fontSize: 26,
        ),
      ),
      actions: [
        Consumer<FriendProvider>(
          builder: (context, friendState, _) {
            final count = friendState.pendingIncomingRequests.length;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FriendRequestsScreen(),
                      ),
                    );
                  },
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          tooltip: 'Nearby',
          icon: Icon(Icons.travel_explore_rounded, color: iconColor, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NearbyScreen()),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.camera_alt_outlined, color: iconColor, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
