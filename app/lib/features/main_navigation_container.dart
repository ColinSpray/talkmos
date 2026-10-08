import 'dart:async';
import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/features/calls/services/call_signaling/call_signaling_service.dart';
import 'package:talkmos/features/profile/screens/profile_screen.dart';
import 'package:talkmos/features/users/screens/select_contact_screen.dart';
import '../providers/providers.dart';
import 'calls/screens/calls_screen.dart';
import 'chats/screens/home_screen.dart';
import '../core/services/token_manager.dart';

import 'chats/widgets/new_chat_icon.dart';
import 'system/services/splash_gate.dart';
import 'system/services/startup_permissions.dart';
import 'system/services/app_update_service.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _selectedIndex = 0;

  late final CallSignalingService _signalingService;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _signalingService = context.read<CallSignalingService>();

    _screens = [
      const HomeScreen(),
      CallsScreen(signalingService: _signalingService),
      const ProfileScreen(),
    ];

    final user = context.read<AuthProvider>().user;
    final token = TokenManager.token;
    if (user != null && token != null) {
      _signalingService.connect(user.id, token, userName: user.name);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Sequential, not concurrent: both can put a sheet on screen, and the
      // update dialog is the one that should win if an update is due.
      await _checkAppUpdate();
      if (mounted) await StartupPermissions.ensure(context);
    });
  }

  Future<void> _checkAppUpdate() async {
    // Play downloads in the background while the user gets on with things;
    // this returns once there is something to install.
    if (!await AppUpdateService.startIfAvailable()) return;
    // This screen is built underneath the splash overlay, so without waiting
    // the prompt would appear over the splash animation.
    await SplashGate.whenFinished;
    if (!mounted) return;
    _offerRestart();
  }

  void _offerRestart() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.commonUpdateReady),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: l10n.commonUpdateRestart,
          onPressed: AppUpdateService.install,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        isDark: isDark,
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        activeColor: Theme.of(context).primaryColor,
      ),
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'chats_tab_fab',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectContactScreen(),
                    ),
                  );
                },
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: NewChatIcon(
                  size: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}

// ─── Bottom nav ─────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.isDark,
    required this.selectedIndex,
    required this.onTap,
    required this.activeColor,
  });

  final bool isDark;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bgColor = isDark ? const Color(0xFF000814) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE5E7EB),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavTab(
                index: 0,
                selectedIndex: selectedIndex,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: l10n.mainNavigationChatsTab,
                activeColor: activeColor,
                isDark: isDark,
                onTap: onTap,
              ),
              _NavTab(
                index: 1,
                selectedIndex: selectedIndex,
                icon: Icons.call_outlined,
                activeIcon: Icons.call,
                label: l10n.commonCalls,
                activeColor: activeColor,
                isDark: isDark,
                onTap: onTap,
              ),
              _NavTab(
                index: 2,
                selectedIndex: selectedIndex,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: l10n.commonSettings,
                activeColor: activeColor,
                isDark: isDark,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final labelColor = isSelected
        ? activeColor
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF));

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, size: 24, color: labelColor),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 4),
            // Active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
