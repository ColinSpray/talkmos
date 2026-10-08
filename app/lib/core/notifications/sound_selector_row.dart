import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show AudioAttributesUsage;
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../features/calls/services/ringtone_service.dart';
import 'notification_sounds.dart';

class SoundSelectorRow extends StatefulWidget {
  final String title;

  /// Where the choice is persisted (calls vs messages).
  final NotificationSoundStore store;

  /// Rebuilt whenever the choice changes — a channel's sound is fixed at
  /// creation, so a new sound means a new channel.
  final SoundedChannel channel;

  final bool allowSilent;

  /// Notified after a successful save so the parent can refresh.
  final VoidCallback? onChanged;

  const SoundSelectorRow({
    super.key,
    required this.title,
    required this.store,
    required this.channel,
    this.allowSilent = false,
    this.onChanged,
  });

  @override
  State<SoundSelectorRow> createState() => _SoundSelectorRowState();
}

class _SoundSelectorRowState extends State<SoundSelectorRow> {
  NotificationSoundSetting? _setting;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final setting = await widget.store.load();
    if (mounted) setState(() => _setting = setting);
  }

  Future<void> _apply(NotificationSoundSetting setting) async {
    setState(() {
      _setting = setting;
      _busy = true;
    });
    await widget.store.save(setting);
    await widget.channel.ensure(localNotifications, setting);
    if (mounted) setState(() => _busy = false);
    widget.onChanged?.call();
  }

  Future<void> _openOptions() async {
    if (_busy) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).primaryColor;
    final current = _setting ?? NotificationSoundSetting.talkmosDefault;

    final choice = await showModalBottomSheet<_SoundChoice>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF000814) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                      ),
                    ),
                  ),
                ),

                for (final tone in BundledTones.all)
                  _OptionTile(
                    icon: Icons.music_note_rounded,
                    label: tone.displayName,
                    subtitle: l10n.soundSelectorRowIncludedWithTalkmos,
                    isSelected:
                        current.mode == SoundMode.bundled &&
                        BundledTones.byId(current.toneId).id == tone.id,
                    accentColor: accent,
                    onTap: () => Navigator.pop(ctx, _SoundChoice.bundled(tone)),
                  ),

                _OptionTile(
                  icon: Icons.smartphone_rounded,
                  label: l10n.soundSelectorRowPhoneDefault,
                  subtitle: l10n.soundSelectorRowFollowPhoneTone,
                  isSelected: current.mode == SoundMode.system,
                  accentColor: accent,
                  onTap: () => Navigator.pop(ctx, const _SoundChoice.system()),
                ),
                _OptionTile(
                  icon: Icons.library_music_rounded,
                  label: l10n.soundSelectorRowChooseFromDevice,
                  subtitle: l10n.soundSelectorRowPickAnyTone,
                  isSelected: current.mode == SoundMode.custom,
                  accentColor: accent,
                  onTap: () => Navigator.pop(ctx, const _SoundChoice.custom()),
                ),
                if (widget.allowSilent)
                  _OptionTile(
                    icon: Icons.notifications_off_rounded,
                    label: l10n.commonSilent,
                    subtitle: l10n.soundSelectorRowSilentSubtitle,
                    isSelected: current.mode == SoundMode.silent,
                    accentColor: accent,
                    onTap: () =>
                        Navigator.pop(ctx, const _SoundChoice.silent()),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null || !mounted) return;

    switch (choice.kind) {
      case _SoundChoiceKind.bundled:
        await _apply(
          NotificationSoundSetting(
            mode: SoundMode.bundled,
            toneId: choice.tone!.id,
          ),
        );
      case _SoundChoiceKind.silent:
        await _apply(const NotificationSoundSetting(mode: SoundMode.silent));
      case _SoundChoiceKind.system:
        // Which "phone default" to read follows the channel's own purpose, so
        // the Message Sound row can't end up asking for the call ringtone.
        final system = await RingtoneService.systemRingtone(
          forNotification:
              widget.channel.usage != AudioAttributesUsage.notificationRingtone,
        );
        if (!mounted) return;
        await _apply(system ?? NotificationSoundSetting.systemDefault);
      case _SoundChoiceKind.custom:
        final picked = await RingtoneService.pick(currentUri: current.uri);
        // Null means the user backed out — keep whatever they had.
        if (picked == null || !mounted) return;
        await _apply(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sound selection goes through Android's RingtoneManager and per-channel
    // sounds; iOS governs both itself.
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return InkWell(
      onTap: _setting == null ? null : _openOptions,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _setting?.displayName ?? l10n.commonLoading,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (_busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right_rounded, color: secondary),
          ],
        ),
      ),
    );
  }
}

enum _SoundChoiceKind { bundled, system, custom, silent }

class _SoundChoice {
  final _SoundChoiceKind kind;
  final BundledTone? tone;

  const _SoundChoice.bundled(this.tone) : kind = _SoundChoiceKind.bundled;
  const _SoundChoice.system() : kind = _SoundChoiceKind.system, tone = null;
  const _SoundChoice.custom() : kind = _SoundChoiceKind.custom, tone = null;
  const _SoundChoice.silent() : kind = _SoundChoiceKind.silent, tone = null;
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The sheet overrides its own background, so these can't rely on ambient
    // defaults — an unstyled leading icon renders dark-on-dark.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idle = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final titleColor = isDark ? Colors.white : const Color(0xFF000000);

    return ListTile(
      leading: Icon(icon, color: isSelected ? accentColor : idle),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? accentColor : titleColor,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: idle)),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: accentColor, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
