import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/services/media_cache_service.dart';
import 'call_theme_colors.dart';

({List<Participant> visible, int overflow}) _splitParticipants(
  List<Participant> all,
  int cap,
) {
  if (all.length <= cap) return (visible: all, overflow: 0);
  return (visible: all.sublist(0, cap), overflow: all.length - cap);
}

/// Group audio call grid: circular avatars (name + "Speaking" state only —
/// no role badges, there's no backing data for Admin/Speaker/Listener).
class AudioCallGrid extends StatelessWidget {
  final List<Participant> participants;
  final Participant? localParticipant;
  final String? Function(Participant participant, bool isLocal) avatarUrlFor;
  final bool isDark;
  final double topPadding;
  final VoidCallback onShowParticipants;
  final VoidCallback onAddMember;

  const AudioCallGrid({
    super.key,
    required this.participants,
    required this.localParticipant,
    required this.avatarUrlFor,
    required this.isDark,
    required this.topPadding,
    required this.onShowParticipants,
    required this.onAddMember,
  });

  static const int _maxVisibleTiles = 11;

  @override
  Widget build(BuildContext context) {
    final split = _splitParticipants(participants, _maxVisibleTiles);
    final tileCount = split.visible.length + (split.overflow > 0 ? 1 : 0) + 1;

    return Container(
      color: callBgColor(isDark),
      padding: EdgeInsets.fromLTRB(16, topPadding + 96, 16, 170),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: tileCount,
        itemBuilder: (context, i) {
          if (i < split.visible.length) {
            final p = split.visible[i];
            final isLocal = p == localParticipant;
            return AudioParticipantTile(
              participant: p,
              isLocal: isLocal,
              isDark: isDark,
              avatarUrl: avatarUrlFor(p, isLocal),
            );
          }
          final overflowIndex = i - split.visible.length;
          if (split.overflow > 0 && overflowIndex == 0) {
            return AudioOverflowTile(
              count: split.overflow,
              isDark: isDark,
              onTap: onShowParticipants,
            );
          }
          return AudioAddMemberTile(isDark: isDark, onTap: onAddMember);
        },
      ),
    );
  }
}

class AudioParticipantTile extends StatelessWidget {
  final Participant participant;
  final bool isLocal;
  final bool isDark;
  final String? avatarUrl;

  const AudioParticipantTile({
    super.key,
    required this.participant,
    required this.isLocal,
    required this.isDark,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rawName = participant.name.isNotEmpty
        ? participant.name
        : participant.identity;
    final displayName = isLocal ? l10n.commonYou : toTitleCase(rawName);
    final initial = rawName.isNotEmpty ? rawName[0].toUpperCase() : '?';
    final isSpeaking = participant.isSpeaking;
    final isMuted = participant.isMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSpeaking ? callSuccessColor : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: ClipOval(
                child: Container(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl!,
                          cacheManager: MediaCacheService.manager,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isMuted ? callErrorColor : callSuccessColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: callBgColor(isDark), width: 2),
                ),
                child: Icon(
                  isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: callTextPrimary(isDark),
          ),
        ),
        if (isSpeaking)
          const Text(
            'Speaking',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: callSuccessColor,
            ),
          ),
      ],
    );
  }
}

class AudioOverflowTile extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onTap;
  const AudioOverflowTile({
    super.key,
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: callTileBg(isDark),
              border: Border.all(color: callTileBorder(isDark)),
            ),
            child: Center(
              child: Text(
                '+$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count more',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: callTextMuted(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class AudioAddMemberTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const AudioAddMemberTile({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add Member',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
