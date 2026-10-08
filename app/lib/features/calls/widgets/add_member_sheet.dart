import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../chats/utils/contact_candidates.dart';
import '../services/call_signaling/call_signaling_service.dart';
import 'call_theme_colors.dart';

void showAddMemberSheet(
  BuildContext context, {
  required CallSignalingService signalingService,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  final friendProvider = context.read<FriendProvider>();
  if (friendProvider.friends.isEmpty) {
    friendProvider.loadFriendsAndRequests();
  }
  // People you only chat with are invitable too, so the chat list has to be
  // loaded even if this call started before it was.
  final chatProvider = context.read<ChatProvider>();
  if (chatProvider.recentChats.isEmpty) {
    chatProvider.loadRecentChats();
  }
  final myName = context.read<AuthProvider>().user?.name ?? '';
  final messenger = ScaffoldMessenger.of(context);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: (isDark ? const Color(0xFF161F33) : Colors.white).withValues(
              alpha: 0.95,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).padding.bottom + 16,
            ),
            child: SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: Consumer2<FriendProvider, ChatProvider>(
                  builder: (context, fp, cp, _) {
                    final inCall = {
                      ...signalingService.remoteParticipants.map(
                        (p) => p.identity,
                      ),
                      if (signalingService.room?.localParticipant != null)
                        signalingService.room!.localParticipant!.identity,
                    };
                    final friends = contactCandidates(
                      friends: fp.friends,
                      chats: [...cp.recentChats, ...cp.archivedChats],
                      myId: cp.user?.id,
                      exclude: inCall,
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        // Grab bar handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.activeCallScreenAddToCall,
                                style: TextStyle(
                                  color: callTextPrimary(isDark),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFF1F5F9),
                          height: 1,
                        ),
                        if (friends.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              l10n.activeCallScreenNoContactsAvailable,
                              style: TextStyle(
                                color: callTextMuted(isDark),
                                fontSize: 15,
                              ),
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.45,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: friends.length,
                              separatorBuilder: (_, __) => Divider(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFF1F5F9),
                                height: 1,
                              ),
                              itemBuilder: (context, i) {
                                final f = friends[i];
                                final avatar = f.avatarUrl;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 4,
                                  ),
                                  leading: AvatarCircle(
                                    imageUrl: avatar,
                                    radius: 22,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.25),
                                    fallback: Text(
                                      f.name.isNotEmpty
                                          ? f.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    toTitleCase(f.name),
                                    style: TextStyle(
                                      color: callTextPrimary(isDark),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: f.username != null
                                      ? Text(
                                          '@${f.username}',
                                          style: TextStyle(
                                            color: callTextMuted(isDark),
                                            fontSize: 13,
                                          ),
                                        )
                                      : null,
                                  trailing: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.phone_callback_rounded,
                                      color: Theme.of(context).primaryColor,
                                      size: 18,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    signalingService.inviteToCall(
                                      f.id,
                                      initiatorName: myName,
                                    );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.activeCallScreenCallingName(
                                            toTitleCase(f.name),
                                          ),
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
