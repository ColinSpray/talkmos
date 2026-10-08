import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../services/chat_service/chat_service.dart';
import '../widgets/group_settings_widgets.dart';

/// Who a given group action is open to.
enum PermissionAudience { everyone, admins }

class _PermissionSpec {
  final String key;
  final IconData icon;

  const _PermissionSpec({required this.key, required this.icon});
}

/// Group permission settings. Admin/owner only — the server enforces this too,
/// so a non-admin reaching this screen still can't change anything.
class GroupPermissionsScreen extends StatefulWidget {
  final String chatId;

  /// Current values as returned by `getConversationDetails`.
  final Map<String, dynamic> permissions;

  /// Whether the viewer may edit. Read-only for ordinary members.
  final bool canEdit;

  const GroupPermissionsScreen({
    super.key,
    required this.chatId,
    required this.permissions,
    required this.canEdit,
  });

  @override
  State<GroupPermissionsScreen> createState() => _GroupPermissionsScreenState();
}

class _GroupPermissionsScreenState extends State<GroupPermissionsScreen> {
  static const List<_PermissionSpec> _specs = [
    _PermissionSpec(key: 'sendMessages', icon: Icons.chat_bubble_rounded),
    _PermissionSpec(key: 'editInfo', icon: Icons.edit_rounded),
    _PermissionSpec(key: 'addMembers', icon: Icons.person_add_alt_1_rounded),
  ];

  final _chatService = ChatService();
  late Map<String, String> _values;
  String? _savingKey;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final spec in _specs)
        spec.key: _normalise(widget.permissions[spec.key], spec.key),
    };
  }

  /// Falls back to the server-side defaults when a value is missing or
  /// unrecognised, so an older chat document still renders sensibly.
  static String _normalise(dynamic raw, String key) {
    final value = raw?.toString();
    if (value == 'everyone' || value == 'admins') return value!;
    return key == 'sendMessages' ? 'everyone' : 'admins';
  }

  static String _labelFor(AppLocalizations l10n, String key) {
    switch (key) {
      case 'editInfo':
        return l10n.groupPermissionsScreenEditInfoLabel;
      case 'addMembers':
        return l10n.groupPermissionsScreenAddMembersLabel;
      default:
        return l10n.groupPermissionsScreenSendMessagesLabel;
    }
  }

  static String _descriptionFor(AppLocalizations l10n, String key) {
    switch (key) {
      case 'editInfo':
        return l10n.groupPermissionsScreenEditInfoDescription;
      case 'addMembers':
        return l10n.groupPermissionsScreenAddMembersDescription;
      default:
        return l10n.groupPermissionsScreenSendMessagesDescription;
    }
  }

  Future<void> _set(String key, String value) async {
    if (_values[key] == value) return;
    final previous = _values[key]!;

    setState(() {
      _values[key] = value;
      _savingKey = key;
    });

    try {
      await _chatService.updateGroupPermissions(widget.chatId, {key: value});
    } catch (e) {
      // Roll back so the screen never shows a restriction that isn't live.
      if (mounted) {
        setState(() => _values[key] = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).groupPermissionsScreenUpdateFailed('$e'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final surface = isDark ? const Color(0xFF070C17) : const Color(0xFFF6F7FB);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context, _values),
        ),
        title: Text(
          l10n.commonPermissions,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (!widget.canEdit)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.groupPermissionsScreenAdminOnlyNotice,
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                  ),
                ],
              ),
            ),

          for (final spec in _specs)
            GroupSettingsSection(
              icon: spec.icon,
              title: _labelFor(l10n, spec.key),
              accent: primary,
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    _descriptionFor(l10n, spec.key),
                    style: TextStyle(fontSize: 13, color: secondary),
                  ),
                ),
                for (final audience in PermissionAudience.values)
                  _buildOption(
                    spec: spec,
                    audience: audience,
                    isDark: isDark,
                    textColor: textColor,
                    secondary: secondary,
                    primary: primary,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required _PermissionSpec spec,
    required PermissionAudience audience,
    required bool isDark,
    required Color textColor,
    required Color secondary,
    required Color primary,
  }) {
    final value = audience.name;
    final selected = _values[spec.key] == value;
    final busy = _savingKey == spec.key;

    return InkWell(
      onTap: widget.canEdit && !busy ? () => _set(spec.key, value) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(
              audience == PermissionAudience.everyone
                  ? Icons.groups_rounded
                  : Icons.shield_rounded,
              size: 20,
              color: selected ? primary : secondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                audience == PermissionAudience.everyone
                    ? AppLocalizations.of(
                        context,
                      ).groupPermissionsScreenAllMembers
                    : AppLocalizations.of(
                        context,
                      ).groupPermissionsScreenOnlyAdmins,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.canEdit ? textColor : secondary,
                ),
              ),
            ),
            if (selected) ...[
              if (busy) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.check_circle_rounded, color: primary, size: 22),
            ] else
              Icon(
                Icons.circle_outlined,
                color: secondary.withValues(alpha: 0.6),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
