import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app/app_providers.dart';
import 'core/app/bootstrap.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/calls/widgets/active_call_banner.dart';
import 'features/calls/widgets/active_call_video_pip.dart';
import 'features/calls/widgets/call_host.dart';
import 'features/calls/widgets/pip_mode_video_overlay.dart';
import 'features/system/widgets/session_host.dart';
import 'l10n/gen/app_localizations.dart';
import 'providers/providers.dart';

Future<void> main() async {
  final themeMode = await bootstrapApp();

  // Built here rather than by a provider: the two are wired to each other
  // before there is a tree to look either of them up in.
  final notificationService = NotificationService();
  final authProvider = AuthProvider()
    ..setNotificationService(notificationService);

  runApp(
    AppProviders(
      notificationService: notificationService,
      authProvider: authProvider,
      themeMode: themeMode,
      child: const CallHost(child: SessionHost(child: TalkmosApp())),
    ),
  );
}

class TalkmosApp extends StatelessWidget {
  const TalkmosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      title: 'TalkMos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(settings.primaryColor),
      darkTheme: AppTheme.getDarkTheme(settings.primaryColor),
      themeMode: settings.themeMode,
      locale: context.watch<LocaleProvider>().locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Above the Navigator, so the call banner and the picture-in-picture
      // overlays outlive whatever screen is on show.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _overlayStyle(Theme.of(context).brightness == Brightness.dark),
        child: Stack(
          children: [
            Column(
              children: [
                const ActiveCallBanner(),
                Expanded(child: child!),
              ],
            ),
            const ActiveCallVideoPip(),
            const PipModeVideoOverlay(),
          ],
        ),
      ),
    );
  }

  SystemUiOverlayStyle _overlayStyle(bool isDark) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: isDark ? const Color(0xFF0F172A) : Colors.white,
    systemNavigationBarIconBrightness: isDark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}
