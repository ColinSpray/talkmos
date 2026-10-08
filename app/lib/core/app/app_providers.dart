import 'package:flutter/material.dart';
import '../../features/chats/services/chat_service/chat_service.dart';
import '../../features/chats/services/socket_service/socket_service.dart';
import '../../features/calls/services/call_signaling/call_signaling_service.dart';
import '../../features/profile/services/profile_service.dart';
import '../../features/stories/services/story_service.dart';
import '../../providers/providers.dart';
import '../notifications/notification_service.dart';

/// The app's shared state, published above every screen.
///
/// [notificationService] and [authProvider] are built in `main` — they are
/// wired to each other before the tree exists — so both go in as values.
class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    required this.notificationService,
    required this.authProvider,
    required this.themeMode,
    required this.child,
  });

  final NotificationService notificationService;
  final AuthProvider authProvider;
  final ThemeMode themeMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: notificationService),
        Provider<ProfileService>(create: (_) => ProfileService()),
        Provider<StoryService>(create: (_) => StoryService()),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SocketService>(create: (_) => SocketService()),
        ChangeNotifierProvider<CallSignalingService>(
          create: (_) => CallSignalingService(),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, SocketService, ChatProvider>(
          create: (context) => ChatProvider(
            chatService: ChatService(),
            socketService: context.read<SocketService>(),
            user: context.read<AuthProvider>().user,
          ),
          update: (context, auth, socket, chatProvider) {
            chatProvider!.updateUser(auth.user);
            return chatProvider;
          },
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          SocketService,
          FriendProvider
        >(
          create: (context) => FriendProvider(
            currentUser: context.read<AuthProvider>().user,
            socketService: context.read<SocketService>(),
          ),
          update: (context, auth, socket, friendProvider) {
            friendProvider!.updateUser(auth.user);
            return friendProvider;
          },
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(initialThemeMode: themeMode),
        ),
        ChangeNotifierProvider<CommunityProvider>(
          create: (_) => CommunityProvider(),
        ),
        ChangeNotifierProvider<StoryProvider>(create: (_) => StoryProvider()),
        ChangeNotifierProvider<BlockProvider>(create: (_) => BlockProvider()),
        ChangeNotifierProvider<NearbyProvider>(create: (_) => NearbyProvider()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: child,
    );
  }
}
