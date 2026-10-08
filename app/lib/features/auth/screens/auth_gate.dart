import 'dart:async';
import 'package:flutter/material.dart';
import '../../../providers/providers.dart';
import '../../main_navigation_container.dart';
import '../../system/services/splash_gate.dart';
import '../../calls/services/call_notification_service.dart';
import 'complete_profile_screen.dart';
import 'phone_confirmation_screen.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

/// The first screen: holds the splash over whatever the session turns out to
/// need — sign-in, profile completion, or the app itself.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static bool _splashPlayed = false;

  late bool _splashDone = _splashPlayed;
  bool _contentSettled = false;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    // Re-entering the gate after an auth flow skips the splash entirely, so
    // nothing is going to raise this later.
    if (_splashDone) SplashGate.markFinished();
    CallNotificationService.skipSplashReveal.addListener(_onSkipSplashChanged);
    if (CallNotificationService.skipSplashReveal.value) _onSkipSplashChanged();
  }

  void _onSkipSplashChanged() {
    if (CallNotificationService.skipSplashReveal.value &&
        mounted &&
        !_splashDone) {
      _splashPlayed = true;
      SplashGate.markFinished();
      setState(() => _splashDone = true);
    }
  }

  void _scheduleSettle() {
    if (_contentSettled || _settleTimer != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settleTimer = Timer(const Duration(milliseconds: 320), () {
        if (mounted) setState(() => _contentSettled = true);
      });
    });
  }

  @override
  void dispose() {
    CallNotificationService.skipSplashReveal.removeListener(
      _onSkipSplashChanged,
    );
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isInitialized) _scheduleSettle();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (auth.isInitialized) _destination(auth) else const SizedBox.shrink(),
        if (!_splashDone)
          SplashScreen(
            ready: _contentSettled,
            onRevealComplete: () {
              _splashPlayed = true;
              SplashGate.markFinished();
              if (mounted) setState(() => _splashDone = true);
            },
          ),
      ],
    );
  }

  Widget _destination(AuthProvider auth) {
    if (!auth.isAuthenticated) {
      return const WelcomeScreen();
    }
    final name = auth.user?.name ?? '';
    if (name.isEmpty) {
      return const CompleteProfileScreen();
    }
    if (auth.requiresPhoneConfirmation) {
      return const PhoneConfirmationScreen();
    }
    return const MainNavigationContainer();
  }
}
