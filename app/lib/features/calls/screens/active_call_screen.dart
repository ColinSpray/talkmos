import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import '../../../providers/providers.dart';
import '../../../core/router/app_router.dart';
import '../services/call_signaling/call_signaling_service.dart';
import '../utils/call_duration.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/audio_call_center_content.dart';
import '../widgets/audio_call_grid.dart';
import '../widgets/call_control_hud.dart';
import '../widgets/call_header.dart';
import '../widgets/call_reactions.dart';
import '../widgets/call_avatar_circle.dart';
import '../widgets/call_theme_colors.dart';
import '../widgets/call_utility_row.dart';
import '../widgets/participants_sheet.dart';
import '../widgets/remote_camera_off_view.dart';
import '../widgets/self_pip_preview.dart';
import '../widgets/video_call_grid.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class ActiveCallScreen extends StatefulWidget {
  final CallSignalingService signalingService;

  const ActiveCallScreen({super.key, required this.signalingService});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen>
    with SingleTickerProviderStateMixin {
  Timer? _durationTimer;

  /// Read off the call's own start time rather than counted here: this
  /// screen is closed and rebuilt every time the user leaves and taps back
  /// in, and a tick count would start again from zero each time (and drift
  /// while the app sits in the background).
  int get _secondsElapsed {
    final start = _sig.connectedAt;
    if (start == null) return 0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return elapsed > 0 ? elapsed : 0;
  }

  bool _hasPopped = false;
  bool _isHangingUp = false;

  /// Tapping the small self tile in a 1:1 video call swaps the two views, so
  /// my own camera fills the screen and the peer moves into the tile.
  bool _isSelfFullscreen = false;

  late final AnimationController _pulseController;

  final Random _random = Random();
  StreamSubscription<CallReactionEvent>? _reactionSub;
  final List<CallReaction> _floatingReactions = [];
  bool _showReactionPicker = false;

  VideoTrack? _cachedRemoteTrack;
  Widget? _cachedRemoteVideoRenderer;
  VideoTrack? _cachedLocalTrack;
  Widget? _cachedLocalVideoRenderer;

  String? _lastVideoStateSignature;

  Widget _remoteVideoWidget(VideoTrack track) {
    if (!identical(_cachedRemoteTrack, track) ||
        _cachedRemoteVideoRenderer == null) {
      _cachedRemoteTrack = track;
      _cachedRemoteVideoRenderer = VideoTrackRenderer(
        track,
        fit: VideoViewFit.cover,
      );
    }
    return _cachedRemoteVideoRenderer!;
  }

  Widget? _localVideoWidget(VideoTrack? track) {
    if (track == null) {
      _cachedLocalTrack = null;
      _cachedLocalVideoRenderer = null;
      return null;
    }
    if (!identical(_cachedLocalTrack, track) ||
        _cachedLocalVideoRenderer == null) {
      _cachedLocalTrack = track;
      _cachedLocalVideoRenderer = VideoTrackRenderer(
        track,
        fit: VideoViewFit.cover,
        mirrorMode: VideoViewMirrorMode.mirror,
      );
    }
    return _cachedLocalVideoRenderer!;
  }

  /// The peer, shrunk into the tile while my own camera holds the screen.
  Widget _pipPeerWidget(bool isDark, String? avatarUrl, String initials) {
    final remoteTrack = _sig.remoteVideoTrack;
    if (remoteTrack != null) return _remoteVideoWidget(remoteTrack);
    return Container(
      color: callTileBg(isDark),
      child: Center(
        child: CallAvatarCircle(
          isDark: isDark,
          avatarUrl: avatarUrl,
          initials: initials,
          borderColor: callTileBorder(isDark),
          size: 64,
        ),
      ),
    );
  }

  /// Me, while my own camera is off — my avatar rather than the frame the
  /// camera stopped on.
  Widget _pipSelfWidget(bool isDark) {
    String? avatarUrl;
    String name = '';
    try {
      final me = context.read<AuthProvider>().user;
      avatarUrl = me?.avatarUrl;
      name = me?.name ?? '';
    } catch (_) {}
    return Container(
      color: callTileBg(isDark),
      child: Center(
        child: CallAvatarCircle(
          isDark: isDark,
          avatarUrl: avatarUrl,
          initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
          borderColor: callTileBorder(isDark),
          size: 56,
        ),
      ),
    );
  }

  CallSignalingService get _sig => widget.signalingService;

  @override
  void initState() {
    super.initState();
    _sig.markActiveCallScreenOpened();
    _sig.addListener(_onSignalingChanged);
    _startTimerIfNeeded();
    _reactionSub = _sig.onReaction.listen(_onReactionReceived);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  /// True if either side of a 1:1 call is currently talking — drives the
  /// avatar's speaking glow (see PulsingAvatar).
  bool _isAnySpeaking() {
    if (_sig.room?.localParticipant?.isSpeaking ?? false) return true;
    final remotes = _sig.remoteParticipants;
    return remotes.isNotEmpty && remotes.first.isSpeaking;
  }

  void _onReactionReceived(CallReactionEvent event) {
    if (!mounted) return;
    final reaction = CallReaction(
      id: event.id,
      emoji: event.emoji,
      dx: _random.nextDouble(),
    );
    setState(() => _floatingReactions.add(reaction));
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(
        () => _floatingReactions.removeWhere((r) => r.id == reaction.id),
      );
    });
  }

  void _onSignalingChanged() {
    if (!mounted) return;
    _startTimerIfNeeded();
    _stopTimerIfEnded();
    if (_maybeAutoPop()) return;
    setState(() {});
  }

  void _startTimerIfNeeded() {
    if (_sig.state == CallState.connected && _durationTimer == null) {
      // Only here to repaint once a second — the value itself is derived.
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _stopTimerIfEnded() {
    if (_sig.state == CallState.ended || _sig.state == CallState.idle) {
      _durationTimer?.cancel();
      _durationTimer = null;
    }
  }

  /// Closes the screen once the call is over. Returns true if the call has
  /// ended, so the caller can skip repainting a torn-down call.
  bool _maybeAutoPop() {
    if (_sig.state != CallState.ended && _sig.state != CallState.idle) {
      return false;
    }
    if (_hasPopped) return true;
    _hasPopped = true;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      AppRouter.router.go(AppRoutes.mainNav);
    }
    return true;
  }

  /// What to say in place of the peer's video. Their camera being off is the
  /// common case once connected, so only say "connecting" while they really
  /// are publishing a camera track we have yet to receive.
  String _remoteVideoStatusText(AppLocalizations l10n, String peerName) {
    if (_sig.isPeerReconnecting) return l10n.activeCallScreenReconnecting;
    if (_sig.state != CallState.connected) {
      return _sig.state == CallState.ringingOutgoing && !_sig.calleeRinging
          ? l10n.activeCallScreenCalling
          : l10n.activeCallScreenRinging;
    }
    final remotes = _sig.remoteParticipants;
    if (remotes.isNotEmpty && remotes.first.isCameraEnabled()) {
      return l10n.activeCallScreenConnectingVideoWith(toTitleCase(peerName));
    }
    return l10n.activeCallScreenCameraOff;
  }

  String? _findPeerAvatarUrl() {
    final remotes = _sig.remoteParticipants;
    if (remotes.length == 1 && remotes.first.identity != _sig.peerId) {
      return _avatarUrlForParticipant(remotes.first, false);
    }

    if (_sig.peerAvatar != null && _sig.peerAvatar!.isNotEmpty) {
      return _sig.peerAvatar;
    }
    final peerId = _sig.peerId;
    if (peerId != null && peerId.isNotEmpty) {
      try {
        final friends = context.read<FriendProvider>().friends;
        for (final f in friends) {
          if (f.id == peerId &&
              f.avatarUrl != null &&
              f.avatarUrl!.isNotEmpty) {
            return f.avatarUrl;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  String? _avatarUrlForParticipant(Participant participant, bool isLocal) {
    if (isLocal) {
      try {
        return context.read<AuthProvider>().user?.avatarUrl;
      } catch (_) {
        return null;
      }
    }
    final identity = participant.identity;
    try {
      final friends = context.read<FriendProvider>().friends;
      for (final f in friends) {
        if (f.id == identity &&
            f.avatarUrl != null &&
            f.avatarUrl!.isNotEmpty) {
          return f.avatarUrl;
        }
      }
    } catch (_) {}
    return null;
  }

  List<Participant> _allParticipants() {
    final list = <Participant>[];
    final local = _sig.room?.localParticipant;
    if (local != null) list.add(local);
    list.addAll(_sig.remoteParticipants);
    return list;
  }

  Future<void> _handleHangUp() async {
    if (_isHangingUp) return;
    setState(() => _isHangingUp = true);

    _durationTimer?.cancel();
    _durationTimer = null;

    _sig.cleanUp();

    if (mounted && !_hasPopped) {
      _hasPopped = true;
      Navigator.pop(context);
    }
  }

  Future<void> _handleUpgradeToVideo() async {
    debugPrint('[UpgradeVideo] > "Start Video" button TAPPED');
    try {
      await _sig.upgradeToVideo();
      debugPrint('[UpgradeVideo] upgrade completed without error');
    } catch (e, st) {
      debugPrint('[UpgradeVideo] FAILED: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start video: $e')));
    }
  }

  Future<void> _handleToggleCamera() async {
    debugPrint('[ToggleCamera] > camera button TAPPED');
    try {
      await _sig.toggleCamera();
      debugPrint('[ToggleCamera] completed without error');
    } catch (e, st) {
      debugPrint('[ToggleCamera] FAILED: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start video: $e')));
    }
  }

  Future<void> _handleToggleScreenShare() async {
    try {
      await _sig.toggleScreenShare();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not share screen: $e')));
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _reactionSub?.cancel();
    _sig.removeListener(_onSignalingChanged);
    _sig.markActiveCallScreenClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_sig.state == CallState.ended || _sig.state == CallState.idle) {
      return Scaffold(backgroundColor: callBgColor(isDark));
    }

    final bool iSentVideo = _sig.callType == 'video';
    final bool isVideo = iSentVideo || _sig.hasRemoteVideoPublication;
    final bool isGroup = _sig.isGroupCall;
    final videoStateSignature =
        '${_sig.callType}|$isVideo|${_sig.hasRemoteVideo}|'
        '${_sig.remoteVideoTrack != null}|${_sig.localVideoTrack != null}|'
        '${_sig.isCameraOff}|$isGroup';
    if (videoStateSignature != _lastVideoStateSignature) {
      _lastVideoStateSignature = videoStateSignature;
      debugPrint(
        '[CallUI] callType=${_sig.callType}, isVideo=$isVideo, '
        'hasRemoteVideo=${_sig.hasRemoteVideo}, '
        'remoteVideoTrack=${_sig.remoteVideoTrack != null}, '
        'localVideoTrack=${_sig.localVideoTrack != null}, '
        'isCameraOff=${_sig.isCameraOff}, isGroup=$isGroup',
      );
    }
    // Whoever is actually on the call, not whoever it started with — the
    // caller can hang up on a group call while the rest keep talking.
    final String activeTitle = _sig.activeCallTitle;
    final String peerName = activeTitle.isNotEmpty
        ? activeTitle
        : (_sig.peerName ?? l10n.commonUnknown);
    final CallState callState = _sig.state;
    final initials = peerName.isNotEmpty ? peerName[0].toUpperCase() : '?';
    final avatarUrl = _findPeerAvatarUrl();
    final bool isRinging =
        callState == CallState.ringingIncoming ||
        callState == CallState.ringingOutgoing;
    final bool isSpeakingNow = _isAnySpeaking();
    final bool showAvatarPulse = isRinging || isSpeakingNow;
    final Color avatarGlowColor = isSpeakingNow
        ? callSuccessColor
        : Theme.of(context).primaryColor;

    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final allParticipants = _allParticipants();
    final localParticipant = _sig.room?.localParticipant;

    // Only swappable while my camera is actually running — otherwise the tile
    // has nothing to promote, so the swap silently falls back.
    final bool swapped = _isSelfFullscreen && _sig.localVideoTrack != null;

    Participant? speaking;
    for (final p in allParticipants) {
      if (p.isSpeaking) {
        speaking = p;
        break;
      }
    }

    return Scaffold(
      backgroundColor: callBgColor(isDark),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Instagram-style full-bleed blurred backdrop, 1:1 audio call ──
          if (!isGroup && !isVideo)
            Positioned.fill(
              child: BlurredAvatarBackdrop(
                isDark: isDark,
                avatarUrl: avatarUrl,
              ),
            ),

          // ── Group call: participant grid ───────────────────────────────
          if (isGroup) ...[
            Positioned.fill(
              child: isVideo
                  ? VideoCallGrid(
                      participants: allParticipants,
                      localParticipant: localParticipant,
                      videoTrackFor: _sig.videoTrackFor,
                      isDark: isDark,
                      topPadding: topPadding,
                      onSwitchCamera: _sig.switchCamera,
                      onShowParticipants: () => showCallParticipantsSheet(
                        context,
                        isDark: isDark,
                        participants: allParticipants,
                        localParticipant: localParticipant,
                        avatarUrlFor: _avatarUrlForParticipant,
                        raisedHandIdentities: _sig.raisedHandIdentities,
                      ),
                      onAddMember: () =>
                          showAddMemberSheet(context, signalingService: _sig),
                    )
                  : AudioCallGrid(
                      participants: allParticipants,
                      localParticipant: localParticipant,
                      avatarUrlFor: _avatarUrlForParticipant,
                      isDark: isDark,
                      topPadding: topPadding,
                      onShowParticipants: () => showCallParticipantsSheet(
                        context,
                        isDark: isDark,
                        participants: allParticipants,
                        localParticipant: localParticipant,
                        avatarUrlFor: _avatarUrlForParticipant,
                        raisedHandIdentities: _sig.raisedHandIdentities,
                      ),
                      onAddMember: () =>
                          showAddMemberSheet(context, signalingService: _sig),
                    ),
            ),
          ]
          // ── Remote Video Stream (1:1 Video Call) ─────────────────────────
          else if (isVideo) ...[
            Positioned.fill(
              child: swapped
                  ? _localVideoWidget(_sig.localVideoTrack)!
                  : (_sig.remoteVideoTrack != null
                        ? _remoteVideoWidget(_sig.remoteVideoTrack!)
                        : RemoteCameraOffView(
                            isDark: isDark,
                            avatarUrl: avatarUrl,
                            initials: initials,
                            statusText: _remoteVideoStatusText(l10n, peerName),
                            isSpeakingNow: isSpeakingNow,
                            showAvatarPulse: showAvatarPulse,
                            avatarGlowColor: avatarGlowColor,
                            pulseAnimation: _pulseController,
                          )),
            ),
            if (swapped)
              Positioned(
                right: 16,
                top: topPadding + 120,
                child: GestureDetector(
                  onTap: _sig.switchCamera,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flip_camera_ios_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ]
          // ── Audio Call Center Content (1:1) ─────────────────────────────
          else ...[
            AudioCallCenterContent(
              isDark: isDark,
              avatarUrl: avatarUrl,
              initials: initials,
              peerName: toTitleCase(peerName),
              isConnected: callState == CallState.connected,
              statusText: _sig.isPeerReconnecting
                  ? l10n.activeCallScreenReconnecting
                  : (callState == CallState.connected || _secondsElapsed > 0)
                  ? formatCallDuration(Duration(seconds: _secondsElapsed))
                  : (callState == CallState.ringingOutgoing &&
                        !_sig.calleeRinging)
                  ? l10n.activeCallScreenCalling
                  : l10n.activeCallScreenRinging,
              isSpeakingNow: isSpeakingNow,
              showAvatarPulse: showAvatarPulse,
              avatarGlowColor: avatarGlowColor,
              pulseAnimation: _pulseController,
            ),
          ],

          // ── Floating reactions overlay ────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: ReactionOverlay(reactions: _floatingReactions),
            ),
          ),

          // ── Top Header / Status Overlay ──────────────────────────────────
          Positioned(
            top: topPadding + 8,
            left: 16,
            right: 16,
            child: CallHeader(
              isDark: isDark,
              isVideo: isVideo,
              isGroup: isGroup,
              callState: callState,
              peerName: peerName,
              participantCount: allParticipants.length,
              speakingParticipantName: speaking != null
                  ? (speaking.name.isNotEmpty
                        ? speaking.name
                        : speaking.identity)
                  : null,
              connectionQuality:
                  localParticipant?.connectionQuality ??
                  ConnectionQuality.unknown,
              formattedDuration: formatCallDuration(
                Duration(seconds: _secondsElapsed),
              ),
              onBack: () {
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              onAddMember: () =>
                  showAddMemberSheet(context, signalingService: _sig),
            ),
          ),

          // ── Bottom Action Control HUD ─────────────────────────────────────
          Positioned(
            bottom: bottomPadding + 24,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGroup) ...[
                  CallUtilityRow(
                    isDark: isDark,
                    isGroup: isGroup,
                    isHandRaised: _sig.isHandRaised,
                    raisedHandCount: _sig.raisedHandIdentities.length,
                    participantCount: allParticipants.length,
                    showReactionPicker: _showReactionPicker,
                    onToggleRaiseHand: _sig.toggleRaiseHand,
                    onShowParticipants: () => showCallParticipantsSheet(
                      context,
                      isDark: isDark,
                      participants: allParticipants,
                      localParticipant: localParticipant,
                      avatarUrlFor: _avatarUrlForParticipant,
                      raisedHandIdentities: _sig.raisedHandIdentities,
                    ),
                    onToggleReactionPicker: () => setState(
                      () => _showReactionPicker = !_showReactionPicker,
                    ),
                    onPickReaction: (emoji) {
                      _sig.sendReaction(emoji);
                      setState(() => _showReactionPicker = false);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                CallControlHud(
                  isDark: isDark,
                  isVideo: isVideo,
                  isMicMuted: _sig.isMicMuted,
                  isCameraOff: _sig.isCameraOff,
                  isSpeakerOn: _sig.isSpeakerOn,
                  isScreenSharing: _sig.isScreenSharing,
                  isHangingUp: _isHangingUp,
                  onToggleMic: _sig.toggleMicrophone,
                  onToggleCamera: _handleToggleCamera,
                  onUpgradeToVideo: _handleUpgradeToVideo,
                  onToggleSpeaker: _sig.toggleSpeakerphone,
                  onToggleScreenShare: _handleToggleScreenShare,
                  onHangUp: _handleHangUp,
                ),
              ],
            ),
          ),

          if (!isGroup && (isVideo || _sig.localVideoTrack != null))
            SelfPipPreview(
              screenSize: screenSize,
              topPadding: topPadding,
              bottomSafeZone: bottomPadding + 130,
              videoChild: swapped
                  ? _pipPeerWidget(isDark, avatarUrl, initials)
                  : (_localVideoWidget(_sig.localVideoTrack) ??
                        _pipSelfWidget(isDark)),
              onSwitchCamera: _sig.switchCamera,
              showSwitchCamera: !swapped,
              onTap: _sig.localVideoTrack == null
                  ? null
                  : () =>
                        setState(() => _isSelfFullscreen = !_isSelfFullscreen),
            ),
        ],
      ),
    );
  }
}
