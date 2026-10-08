import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/keep_awake_service.dart';
import '../../../core/services/pip_service.dart';
import '../../../core/services/proximity_service.dart';
import '../../../providers/providers.dart';
import '../services/call_notification_service.dart';
import '../services/call_signaling/call_signaling_service.dart';

/// Keeps the app's call state and the platform in step: opening the call
/// screen when one starts, driving the picture-in-picture controls, and
/// holding the screen awake for video.
///
/// Sits above the router so a call can raise the screen from anywhere.
class CallHost extends StatefulWidget {
  const CallHost({super.key, required this.child});

  final Widget child;

  @override
  State<CallHost> createState() => _CallHostState();
}

class _CallHostState extends State<CallHost> with WidgetsBindingObserver {
  StreamSubscription<CallNotificationEvent>? _callNotificationSub;
  StreamSubscription<void>? _activeCallReadySub;
  StreamSubscription<String>? _pipActionSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final signalingService = context.read<CallSignalingService>();
    _activeCallReadySub = signalingService.onActiveCallReady.listen((_) {
      if (mounted && !signalingService.hasActiveCallScreenOpen) {
        CallNotificationService.skipSplashReveal.value = true;
        AppRouter.router.push(AppRoutes.activeCall);
      }
    });
    _callNotificationSub = CallNotificationService.onEvent.listen((event) {
      if (mounted &&
          event.action == CallNotificationAction.open &&
          !signalingService.hasActiveCallScreenOpen) {
        CallNotificationService.skipSplashReveal.value = true;
        AppRouter.router.push(AppRoutes.activeCall);
      }
    });
    // Replays a cold-start launch from a call notification now that the
    // listeners above are ready to catch what it triggers.
    signalingService.reconcileFromNativeCall(
      context.read<AuthProvider>().user?.id ?? '',
    );

    signalingService.onNonFatalCallError = _showCallError;
    signalingService.addListener(_syncNativeCallState);
    _syncNativeCallState();

    _pipActionSub = PipService.instance.onAction.listen((action) {
      switch (action) {
        case 'mute':
          signalingService.toggleMicrophone();
        case 'speaker':
          signalingService.toggleSpeakerphone();
        case 'hangup':
          signalingService.cleanUp();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final signaling = context.read<CallSignalingService>();
    signaling.onNonFatalCallError = null;
    signaling.removeListener(_syncNativeCallState);
    KeepAwakeService.instance.setEnabled(false);
    ProximityService.instance.setEnabled(false);
    _callNotificationSub?.cancel();
    _activeCallReadySub?.cancel();
    _pipActionSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    _reconcileNativeCallState();
    // Coming back from another app can leave the audio routed elsewhere.
    context.read<CallSignalingService>().reapplyAudioPreferences();
  }

  /// Something the call could not do, that did not end it — said above the
  /// app, since the user may be on any screen when it comes back.
  void _showCallError(String message) {
    final navigator = AppRouter.rootNavigatorKey.currentContext;
    if (navigator == null) return;
    ScaffoldMessenger.of(navigator).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _syncNativeCallState() {
    final sig = context.read<CallSignalingService>();
    KeepAwakeService.instance.setEnabled(
      sig.hasActiveCallSession && sig.isVideoCall,
    );
    // Earpiece calls only — the two are opposites, so they never fight over
    // the screen.
    ProximityService.instance.setEnabled(
      sig.hasActiveCallSession && !sig.isVideoCall && !sig.isSpeakerOn,
    );
    PipService.instance.updateCallState(
      active: sig.state == CallState.connected,
      isVideo: sig.isVideoCall,
      isMicMuted: sig.isMicMuted,
      isSpeakerOn: sig.isSpeakerOn,
    );
  }

  Future<void> _reconcileNativeCallState() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    await context.read<CallSignalingService>().reconcileFromNativeCall(userId);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
