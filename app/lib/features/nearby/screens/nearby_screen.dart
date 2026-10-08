import 'package:flutter/material.dart';
import '../../../models/nearby_user_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/providers.dart';
import '../widgets/nearby_consent_sheet.dart';
import '../widgets/nearby_filter_bar.dart';
import '../widgets/nearby_user_card.dart';
import 'nearby_request_sheet.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen>
    with WidgetsBindingObserver {
  /// Captured rather than read on demand: dispose() needs it, and
  /// context.read there is not safe once the element is being unmounted.
  late final NearbyProvider _nearby = context.read<NearbyProvider>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _nearby.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Not awaited — dispose cannot be async, and the provider's stop() is
    // written to be safe to fire and forget.
    _nearby.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _nearby.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _nearby.stop();
    }
  }

  Future<void> _onConsent() async {
    if (!await NearbyConsentSheet.show(context)) return;
    if (!mounted) return;
    await _nearby.enableAndStart();
  }

  Future<void> _onTapUser(NearbyUserModel user) async {
    final message = await NearbyRequestSheet.show(context, user);
    if (message == null || !mounted) return;

    final error = await _nearby.sendRequest(userId: user.id, message: message);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Request sent to ${user.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onReportUser(NearbyUserModel user) async {
    final blocked = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.red),
              title: Text('Block ${user.name}'),
              subtitle: const Text(
                "They won't see you nearby, and can't contact you.",
              ),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    );

    if (blocked != true || !mounted) return;
    await context.read<BlockProvider>().blockUser(
      UserModel(id: user.id, name: user.name, avatarUrl: user.avatarUrl),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} blocked'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<NearbyProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 24,
            color: isDark ? Colors.white : const Color(0xFF000000),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nearby',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF000000),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (state.status == NearbyStatus.running)
            IconButton(
              tooltip: 'Turn off Nearby',
              icon: Icon(
                Icons.visibility_off_outlined,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
              onPressed: () async {
                final error = await _nearby.disable();
                if (!mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Couldn't turn Nearby off: $error"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(state, isDark)),
    );
  }

  Widget _emptyState(NearbyProvider state, bool isDark) {
    // Filtered to the closest tier, but there are people on the other tab.
    if (state.filter == NearbyFilter.rightHere && state.allUsers.isNotEmpty) {
      final n = state.allUsers.length;
      return _Message(
        icon: Icons.my_location_rounded,
        title: 'No one right here',
        body:
            'Nobody is in the same spot as you, but $n '
            '${n == 1 ? "person is" : "people are"} nearby.',
        actionLabel: 'See all nearby',
        onAction: () async => state.setFilter(NearbyFilter.all),
        isDark: isDark,
      );
    }

    // Running, but no fix ever landed — the list is whatever the server had
    // from an earlier session, which is a different problem from an empty room.
    if (!state.hasPosition) {
      return _Message(
        icon: Icons.location_searching_rounded,
        title: 'Finding your area…',
        body:
            "We couldn't get your approximate area just now, so this list "
            'may be out of date. It usually sorts itself out in a moment.',
        isDark: isDark,
      );
    }

    return _Message(
      icon: Icons.radar_rounded,
      title: 'Looking around…',
      body:
          'Nobody has used Talkmos around here recently. Check back when '
          'there are more people about.',
      isDark: isDark,
    );
  }

  Widget _buildBody(NearbyProvider state, bool isDark) {
    switch (state.status) {
      case NearbyStatus.starting:
        return const Center(child: CircularProgressIndicator());

      case NearbyStatus.needsConsent:
        return _Message(
          icon: Icons.travel_explore_rounded,
          title: 'Find people around you',
          body:
              'See other Talkmos users nearby and send them a message. '
              'Uses your approximate area to work out who is close by.',
          actionLabel: 'Turn on Nearby',
          onAction: _onConsent,
          isDark: isDark,
        );

      case NearbyStatus.locationOff:
        return _Message(
          icon: Icons.location_disabled_rounded,
          title: 'Location is off',
          body:
              'Nearby needs location switched on to work out who is close '
              'by. Turn it on in your device settings, then try again.',
          actionLabel: 'Try again',
          onAction: _nearby.start,
          isDark: isDark,
        );

      case NearbyStatus.locationDenied:
        final canPrompt = state.canPromptForLocation;
        return _Message(
          icon: Icons.lock_outline_rounded,
          title: 'Permission needed',
          body: canPrompt
              ? 'Nearby needs location permission to find people around you. '
                    'Your exact position is never shown to anyone.'
              : 'Nearby needs location permission to find people around you. '
                    'Your device has stopped asking, so it has to be granted '
                    'in Settings.',
          actionLabel: canPrompt ? 'Allow location' : 'Open Settings',
          onAction: canPrompt
              ? _nearby.requestPermissionAndStart
              : _nearby.openSettings,
          isDark: isDark,
        );

      case NearbyStatus.error:
        return _Message(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          body: state.errorMessage ?? 'Please try again.',
          actionLabel: 'Retry',
          onAction: _nearby.start,
          isDark: isDark,
        );

      case NearbyStatus.idle:
        return _Message(
          icon: Icons.radar_rounded,
          title: 'Nearby is off',
          body: 'Turn it back on to see people around you.',
          actionLabel: 'Turn on',
          onAction: _nearby.start,
          isDark: isDark,
        );

      case NearbyStatus.running:
        final users = state.users;
        return Column(
          children: [
            NearbyFilterBar(
              selected: state.filter,
              allCount: state.allUsers.length,
              rightHereCount: state.rightHereCount,
              onChanged: state.setFilter,
            ),
            Expanded(
              child: users.isEmpty
                  ? _emptyState(state, isDark)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            // Two, not three. The photo is what identifies the
                            // person you saw, so it gets the width.
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: users.length,
                      itemBuilder: (_, i) {
                        final user = users[i];
                        return NearbyUserCard(
                          user: user,
                          onTap: () => _onTapUser(user),
                          onReport: () => _onReportUser(user),
                        );
                      },
                    ),
            ),
          ],
        );
    }
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final bool isDark;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6B7280),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
