import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/device_model.dart';
import '../../../providers/auth_provider.dart';
import '../services/device_service.dart';
import '../widgets/settings_section.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _deviceService = DeviceService();
  List<DeviceModel>? _devices;
  String? _error;
  bool _loading = true;
  // Per-device in-flight state, so tapping "Log out" on one row disables
  // only that row rather than the whole screen.
  final Set<String> _revoking = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await _deviceService.getDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmAndRevoke(DeviceModel device) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.devicesScreenLogOutConfirmTitle),
        content: Text(
          l10n.devicesScreenLogOutConfirmMessage(
            device.deviceName.isNotEmpty
                ? device.deviceName
                : l10n.commonUnknown,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.devicesScreenLogOut,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _revoking.add(device.deviceId));
    try {
      await _deviceService.revokeDevice(device.deviceId);
      if (device.isCurrent) {
        if (!mounted) return;
        await context.read<AuthProvider>().logout();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.devicesScreenLoggedOut)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _revoking.remove(device.deviceId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.devicesScreenLogOutFailed(e.toString()))),
      );
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'android':
        return Icons.phone_android_rounded;
      case 'web':
        return Icons.public_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  String _statusLabel(AppLocalizations l10n, DeviceModel device) {
    if (!device.isActive) {
      final at = device.loggedOutAt ?? device.lastActiveAt;
      return l10n.devicesScreenLoggedOutOn(
        DateFormat.yMMMd().add_jm().format(at),
      );
    }
    if (device.isCurrent) return l10n.devicesScreenActiveNow;
    return l10n.devicesScreenLastActive(
      DateFormat.yMMMd().add_jm().format(device.lastActiveAt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkBg : const Color(0xFFFAF9FF);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.devicesScreenTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: theme.primaryColor,
          child: _buildBody(context, l10n, isDark),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, bool isDark) {
    if (_loading && _devices == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _devices == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l10n.devicesScreenLoadFailed(_error!),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      );
    }

    final devices = _devices ?? [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        SettingsInfoBanner(
          title: l10n.devicesScreenBannerTitle,
          message: l10n.devicesScreenBannerMessage,
          isDark: isDark,
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 20),
        if (devices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                l10n.devicesScreenNoDevices,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          SettingsCard(
            isDark: isDark,
            children: [
              for (final device in devices) _deviceRow(l10n, isDark, device),
            ],
          ),
      ],
    );
  }

  Widget _deviceRow(AppLocalizations l10n, bool isDark, DeviceModel device) {
    final secondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final isRevoking = _revoking.contains(device.deviceId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Icon(_platformIcon(device.platform), size: 26, color: secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.deviceName.isNotEmpty
                            ? device.deviceName
                            : l10n.commonUnknown,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                      ),
                    ),
                    if (device.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.devicesScreenThisDevice,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _statusLabel(l10n, device),
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
              ],
            ),
          ),
          if (device.isActive) ...[
            const SizedBox(width: 12),
            isRevoking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: () => _confirmAndRevoke(device),
                    child: Text(
                      l10n.devicesScreenLogOut,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
