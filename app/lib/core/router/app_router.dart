import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../../features/auth/screens/complete_profile_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/phone_confirmation_screen.dart';
import '../../features/auth/screens/phone_login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/calls/screens/active_call_screen.dart';
import '../../features/calls/services/call_signaling/call_signaling_service.dart';
import '../../features/chats/screens/create_group_screen.dart';
import '../../features/deep_links/screens/deep_link_chat_loader.dart';
import '../../features/deep_links/screens/deep_link_invite_loader.dart';
import '../../features/deep_links/screens/deep_link_story_loader.dart';
import '../../features/main_navigation_container.dart';
import '../../features/users/screens/friend_requests_screen.dart';
import '../../features/users/screens/select_contact_screen.dart';
import '../../features/users/screens/user_search_screen.dart';
import '../../features/nearby/screens/nearby_screen.dart';
import '../../features/auth/screens/auth_gate.dart';

abstract class AppRoutes {
  static const root = '/';
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const phoneLogin = '/phone-login';
  static const phoneConfirmation = '/phone-confirmation';
  static const completeProfile = '/complete-profile';
  static const mainNav = '/main';
  static const activeCall = '/active-call';
  static const selectContact = '/select-contact';
  static const userSearch = '/user-search';
  static const friendRequests = '/friend-requests';
  static const nearby = '/nearby';
  static const createGroup = '/create-group';

  static const chatDeepLink = '/chat/:userId';
  static const storyDeepLink = '/story/:storyId';
  static const inviteDeepLink = '/invite/:communityId';

  static String chatDeepLinkPath(String userId) => '/chat/$userId';
  static String storyDeepLinkPath(String storyId) => '/story/$storyId';
  static String inviteDeepLinkPath(String communityId) =>
      '/invite/$communityId';
}

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.root,
    observers: [AnalyticsService.observer],
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneLogin,
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneConfirmation,
        builder: (context, state) => const PhoneConfirmationScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.mainNav,
        builder: (context, state) => const MainNavigationContainer(),
      ),
      GoRoute(
        path: AppRoutes.activeCall,
        builder: (context, state) {
          final signalingService = context.read<CallSignalingService>();
          return ActiveCallScreen(signalingService: signalingService);
        },
      ),
      GoRoute(
        path: AppRoutes.selectContact,
        builder: (context, state) => const SelectContactScreen(),
      ),
      GoRoute(
        path: AppRoutes.userSearch,
        builder: (context, state) => const UserSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.nearby,
        builder: (context, state) => const NearbyScreen(),
      ),
      GoRoute(
        path: AppRoutes.friendRequests,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialTabIndex = extra?['initialTabIndex'] as int? ?? 0;
          return FriendRequestsScreen(initialTabIndex: initialTabIndex);
        },
      ),
      GoRoute(
        path: AppRoutes.createGroup,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatDeepLink,
        builder: (context, state) =>
            DeepLinkChatLoader(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: AppRoutes.storyDeepLink,
        builder: (context, state) =>
            DeepLinkStoryLoader(storyId: state.pathParameters['storyId']!),
      ),
      GoRoute(
        path: AppRoutes.inviteDeepLink,
        builder: (context, state) => DeepLinkInviteLoader(
          communityId: state.pathParameters['communityId']!,
        ),
      ),
    ],
  );
}
