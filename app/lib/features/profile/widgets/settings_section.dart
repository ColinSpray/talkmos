import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Small uppercase heading that labels a group of settings.
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
    );
  }
}

/// Rounded card that groups settings rows, with hairline dividers between
/// them (indented on the left, matching the row text).
class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const SettingsCard({super.key, required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final divider = Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFFE8E8F2),
      ),
    );

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(divider);
      rows.add(children[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE3E3EF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// A settings row with a switch on the right.
class SettingsToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool>? onChanged;
  final IconData? leadingIcon;

  const SettingsToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    this.onChanged,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 22,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: _RowLabel(title: title, subtitle: subtitle, isDark: isDark),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}

class SettingsNavigationRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;
  final IconData? leadingIcon;
  final bool showValueAsPill;

  const SettingsNavigationRow({
    super.key,
    required this.title,
    required this.value,
    required this.isDark,
    this.onTap,
    this.trailing,
    this.leadingIcon,
    this.showValueAsPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 22, color: secondary),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: showValueAsPill
                  ? Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    )
                  : _RowLabel(title: title, subtitle: value, isDark: isDark),
            ),
            const SizedBox(width: 12),
            if (showValueAsPill)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
              ),
            trailing ??
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.chevron_right_rounded, color: secondary),
                ),
          ],
        ),
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _RowLabel({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// Tinted callout used for explanatory notes under a settings group.
class SettingsInfoBanner extends StatelessWidget {
  final String title;
  final String message;
  final bool isDark;
  final IconData icon;

  const SettingsInfoBanner({
    super.key,
    required this.title,
    required this.message,
    required this.isDark,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
