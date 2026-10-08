import 'package:flutter/material.dart';

/// Collapsible group of settings rows with a coloured icon + caps title,
/// matching the Group Settings design.
class GroupSettingsSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final bool isDark;
  final List<Widget> children;

  const GroupSettingsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    required this.isDark,
    required this.children,
  });

  @override
  State<GroupSettingsSection> createState() => _GroupSettingsSectionState();
}

class _GroupSettingsSectionState extends State<GroupSettingsSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: widget.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFEFF1F6),
    );

    final rows = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      if (i > 0) rows.add(divider);
      rows.add(widget.children[i]);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE8EBF2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(widget.icon, size: 22, color: widget.accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: widget.accent,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: widget.isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(children: [divider, ...rows]),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A row inside a [GroupSettingsSection]: rounded icon chip, label, optional
/// trailing value, and either a chevron or a supplied trailing widget.
class GroupSettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isDark;
  final Color? accent;
  final bool isDestructive;
  final VoidCallback? onTap;
  final Widget? trailing;

  const GroupSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    this.value,
    this.accent,
    this.isDestructive = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final tint = isDestructive ? Colors.redAccent : (accent ?? primary);
    final labelColor = isDestructive
        ? Colors.redAccent
        : (isDark ? Colors.white : const Color(0xFF000000));
    final secondary = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            if (value != null) ...[
              Text(value!, style: TextStyle(fontSize: 14, color: secondary)),
              const SizedBox(width: 8),
            ],
            trailing ??
                Icon(Icons.chevron_right_rounded, size: 22, color: secondary),
          ],
        ),
      ),
    );
  }
}
