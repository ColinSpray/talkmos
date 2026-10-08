import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../models/story_group_model.dart';
import '../../../providers/providers.dart';
import '../../stories/screens/create_story_screen.dart';
import '../../stories/screens/story_viewer_screen.dart';

/// Horizontal row of story bubbles: the user's own story first, then
/// everyone else's.
class StoriesRow extends StatelessWidget {
  final bool isDark;

  const StoriesRow({super.key, required this.isDark});

  void _viewStoryGroup(BuildContext context, StoryGroupModel group) {
    if (group.stories.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewerScreen(group: group)),
    );
  }

  void _showCreateStory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storyState = context.watch<StoryProvider>();
    final currentUser = context.read<AuthProvider>().user;

    final myGroup = storyState.storiesFeed.cast<StoryGroupModel?>().firstWhere(
      (g) => g!.user.id == currentUser?.id,
      orElse: () => null,
    );
    final othersGroups = storyState.storiesFeed
        .where((g) => g.user.id != currentUser?.id)
        .toList();

    final hasUnviewed = (StoryGroupModel g) =>
        g.stories.any((s) => !s.isViewed);

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          GestureDetector(
            onTap: storyState.isPostingStory
                ? null
                : (myGroup != null
                      ? () => _viewStoryGroup(context, myGroup)
                      : () => _showCreateStory(context)),
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: myGroup != null
                              ? LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Color(0xFFA855F7),
                                  ],
                                )
                              : null,
                          color: myGroup == null
                              ? (isDark
                                    ? const Color(0xFF000E23)
                                    : const Color(0xFFE2E8F0))
                              : null,
                        ),
                        padding: const EdgeInsets.all(2.5),
                        child: AvatarCircle(
                          imageUrl: currentUser?.avatarUrl,
                          radius: 31,
                          backgroundColor: isDark
                              ? const Color(0xFF000814)
                              : Colors.white,
                          fallback: Text(
                            currentUser?.name.isNotEmpty == true
                                ? currentUser!.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF000000)
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                      if (storyState.isPostingStory)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    AppLocalizations.of(context).homeScreenMyStory,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...othersGroups.map((group) {
            final unviewed = hasUnviewed(group);
            final name = group.user.name;
            final avatar = group.user.avatarUrl;
            return GestureDetector(
              onTap: () => _viewStoryGroup(context, group),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: unviewed
                            ? LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Color(0xFFA855F7),
                                ],
                              )
                            : null,
                        color: unviewed
                            ? null
                            : (isDark
                                  ? const Color(0xFF000E23)
                                  : const Color(0xFFCBD5E1)),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: AvatarCircle(
                        imageUrl: avatar,
                        radius: 31,
                        backgroundColor: isDark
                            ? const Color(0xFF000814)
                            : Colors.white,
                        fallback: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: unviewed
                                ? Theme.of(context).primaryColor
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 68,
                      child: Text(
                        toTitleCase(name).split(' ').first,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
