import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'call_theme_colors.dart';

({List<Participant> visible, int overflow}) _splitParticipants(
  List<Participant> all,
  int cap,
) {
  if (all.length <= cap) return (visible: all, overflow: 0);
  return (visible: all.sublist(0, cap), overflow: all.length - cap);
}

/// Group video call grid: rounded-square tiles (WhatsApp-style) — the local
/// participant is just another tile here, never a floating PIP.
class VideoCallGrid extends StatelessWidget {
  final List<Participant> participants;
  final Participant? localParticipant;
  final VideoTrack? Function(Participant) videoTrackFor;
  final bool isDark;
  final double topPadding;
  final VoidCallback onSwitchCamera;
  final VoidCallback onShowParticipants;
  final VoidCallback onAddMember;

  const VideoCallGrid({
    super.key,
    required this.participants,
    required this.localParticipant,
    required this.videoTrackFor,
    required this.isDark,
    required this.topPadding,
    required this.onSwitchCamera,
    required this.onShowParticipants,
    required this.onAddMember,
  });

  static const int _maxVisibleTiles = 8;

  @override
  Widget build(BuildContext context) {
    final split = _splitParticipants(participants, _maxVisibleTiles);
    final tileCount = split.visible.length + (split.overflow > 0 ? 1 : 0) + 1;
    final columns = participants.length <= 1
        ? 1
        : (participants.length <= 4 ? 2 : 3);

    return Container(
      color: callBgColor(isDark),
      padding: EdgeInsets.fromLTRB(12, topPadding + 96, 12, 170),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: tileCount,
        itemBuilder: (context, i) {
          if (i < split.visible.length) {
            final p = split.visible[i];
            final isLocal = p == localParticipant;
            return VideoParticipantTile(
              participant: p,
              isLocal: isLocal,
              isDark: isDark,
              videoTrack: videoTrackFor(p),
              onSwitchCamera: onSwitchCamera,
            );
          }
          final overflowIndex = i - split.visible.length;
          if (split.overflow > 0 && overflowIndex == 0) {
            return VideoOverflowTile(
              count: split.overflow,
              isDark: isDark,
              onTap: onShowParticipants,
            );
          }
          return VideoAddMemberTile(isDark: isDark, onTap: onAddMember);
        },
      ),
    );
  }
}

class VideoParticipantTile extends StatefulWidget {
  final Participant participant;
  final bool isLocal;
  final bool isDark;
  final VideoTrack? videoTrack;
  final VoidCallback onSwitchCamera;

  const VideoParticipantTile({
    super.key,
    required this.participant,
    required this.isLocal,
    required this.isDark,
    required this.videoTrack,
    required this.onSwitchCamera,
  });

  @override
  State<VideoParticipantTile> createState() => _VideoParticipantTileState();
}

class _VideoParticipantTileState extends State<VideoParticipantTile> {
  VideoTrack? _cachedTrack;
  Widget? _cachedRenderer;

  Widget? _videoWidget(VideoTrack? track) {
    if (track == null) {
      _cachedTrack = null;
      _cachedRenderer = null;
      return null;
    }
    if (!identical(_cachedTrack, track) || _cachedRenderer == null) {
      _cachedTrack = track;
      _cachedRenderer = VideoTrackRenderer(
        track,
        fit: VideoViewFit.cover,
        mirrorMode: widget.isLocal
            ? VideoViewMirrorMode.mirror
            : VideoViewMirrorMode.auto,
      );
    }
    return _cachedRenderer;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final participant = widget.participant;
    final isLocal = widget.isLocal;
    final isDark = widget.isDark;
    final videoTrack = widget.videoTrack;
    final rawName = participant.name.isNotEmpty
        ? participant.name
        : participant.identity;
    final initial = rawName.isNotEmpty ? rawName[0].toUpperCase() : '?';
    final isSpeaking = participant.isSpeaking;
    final isMuted = participant.isMuted;
    final videoWidget = _videoWidget(videoTrack);

    return Container(
      decoration: BoxDecoration(
        color: callTileBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpeaking ? callSuccessColor : callTileBorder(isDark),
          width: isSpeaking ? 3 : 1.5,
        ),
        boxShadow: [
          if (isSpeaking)
            BoxShadow(
              color: callSuccessColor.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoWidget != null)
            videoWidget
          else
            Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF090D16),
                          Color(0xFF151C2C),
                          Color(0xFF0D121F),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.25),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 28,
                      color: isDark
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMuted) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: callErrorColor.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: callTileBorder(isDark)),
                    ),
                    child: Text(
                      isLocal ? l10n.commonYou : toTitleCase(rawName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: callTextPrimary(isDark),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLocal && videoTrack != null)
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: widget.onSwitchCamera,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flip_camera_ios_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VideoOverflowTile extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onTap;
  const VideoOverflowTile({
    super.key,
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: callTileBg(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: callTileBorder(isDark)),
        ),
        child: Center(
          child: Text(
            '+$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: callTextPrimary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoAddMemberTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const VideoAddMemberTile({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        child: Icon(
          Icons.person_add_alt_1_rounded,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
