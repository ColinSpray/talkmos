import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../utils/call_duration.dart';
import '../services/call_signaling/call_signaling_service.dart';

class ActiveCallBanner extends StatelessWidget {
  const ActiveCallBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallSignalingService>(
      builder: (context, sig, _) {
        // Connected video is the video PiP's job; everything else — including
        // a call still ringing — is the way back to the call screen.
        final show =
            sig.hasActiveCallSession &&
            !sig.hasActiveCallScreenOpen &&
            !(sig.state == CallState.connected && sig.isVideoCall);
        return _AnimatedBanner(
          show: show,
          peerName: sig.activeCallTitle.isNotEmpty
              ? sig.activeCallTitle
              : (sig.peerName ?? ''),
          isVideo: sig.callType == 'video',
          connectedAt: sig.connectedAt,
          isRinging: sig.state != CallState.connected,
          calleeRinging: sig.calleeRinging,
        );
      },
    );
  }
}

class _AnimatedBanner extends StatefulWidget {
  final bool show;
  final String peerName;
  final bool isVideo;
  final DateTime? connectedAt;
  final bool isRinging;
  final bool calleeRinging;

  const _AnimatedBanner({
    required this.show,
    required this.peerName,
    required this.isVideo,
    required this.connectedAt,
    required this.isRinging,
    required this.calleeRinging,
  });

  @override
  State<_AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<_AnimatedBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(_AnimatedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.show && !widget.isRinging && _ticker == null) {
      // Only exists to force a rebuild every second for the live duration
      // text below — CallSignalingService itself doesn't notify on a timer.
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if ((!widget.show || widget.isRinging) && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formattedDuration() {
    final start = widget.connectedAt;
    if (start == null) return '00:00';
    return formatCallDuration(DateTime.now().difference(start));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !widget.show
          ? const SizedBox(width: double.infinity, height: 0)
          : Material(
              color: AppTheme.primary,
              elevation: 8,
              shadowColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              child: InkWell(
                onTap: () => AppRouter.router.push(AppRoutes.activeCall),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isVideo
                              ? Icons.videocam_rounded
                              : Icons.call_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isRinging
                              ? (widget.calleeRinging
                                    ? l10n.activeCallScreenRinging
                                    : l10n.activeCallScreenCalling)
                              : _formattedDuration(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.activeCallBannerTapToReturn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
