import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/token_manager.dart';
import '../../../providers/providers.dart';
import '../../calls/services/call_signaling/call_signaling_service.dart';
import '../../chats/services/socket_service/socket_service.dart';

/// Ties the signed-in session to the sockets: connects them when a token
/// appears or the app comes back, and tears everything down on logout.
class SessionHost extends StatefulWidget {
  const SessionHost({super.key, required this.child});

  final Widget child;

  @override
  State<SessionHost> createState() => _SessionHostState();
}

class _SessionHostState extends State<SessionHost> with WidgetsBindingObserver {
  String? _lastToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().initialize();
      context.read<AuthProvider>().addListener(_onAuthChanged);
      void endSession() {
        if (mounted) context.read<AuthProvider>().forceLogout();
      }

      context.read<SocketService>().onSessionEnded = endSession;
      context.read<CallSignalingService>().onSessionEnded = endSession;
      _onAuthChanged();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    final currentUser = context.read<AuthProvider>().user;
    final token = TokenManager.token;
    if (currentUser != null && token != null) {
      _connectSockets(currentUser.id, currentUser.name, token);
      unawaited(NearbyProvider.reportPosition());
    }
  }

  void _onAuthChanged() {
    final currentUser = context.read<AuthProvider>().user;
    final token = TokenManager.token;
    if (currentUser != null && token != null) {
      if (_lastToken != token) {
        _lastToken = token;
        _connectSockets(currentUser.id, currentUser.name, token);
      }
    } else {
      _lastToken = null;
      // Both, or the chat socket keeps retrying a token that is now gone.
      context.read<SocketService>().disconnect();
      context.read<CallSignalingService>().disconnect();
      AppRouter.rootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
    }
  }

  void _connectSockets(String userId, String userName, String token) {
    context.read<SocketService>().connect(userId, token);
    context.read<CallSignalingService>().connect(
      userId,
      token,
      userName: userName,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
