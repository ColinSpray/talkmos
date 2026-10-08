import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/users/services/blocked_users_store.dart';
import '../../firebase_options.dart';
import '../../providers/providers.dart';
import '../services/analytics_service.dart';
import '../services/crash_reporting.dart';

/// Everything that has to be in place before the first frame, run as wide as
/// it will go. Returns the theme to start in — read here rather than after
/// mount, so the app never paints the wrong one first.
Future<ThemeMode> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  final splashLogoReady = precacheSplashLogo();
  final themeMode = SettingsProvider.loadPersistedThemeMode();

  await Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
    _initFirebase(),
    _loadEnvAndBlockList(),
  ]);

  await splashLogoReady;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  return themeMode;
}

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  unawaited(AnalyticsService.initialize());
  await CrashReporting.initialize();
}

Future<void> _loadEnvAndBlockList() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
    unawaited(
      CrashReporting.recordError(e, StackTrace.current, reason: 'dotenv load'),
    );
  }
  await BlockedUsersStore.warmUp();
}
