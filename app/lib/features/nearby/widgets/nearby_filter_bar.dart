import 'package:flutter/material.dart';
import '../../../providers/providers.dart';

class NearbyFilterBar extends StatelessWidget {
  final NearbyFilter selected;
  final int allCount;
  final int rightHereCount;
  final ValueChanged<NearbyFilter> onChanged;

  const NearbyFilterBar({
    super.key,
    required this.selected,
    required this.allCount,
    required this.rightHereCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _Chip(
            label: 'Right here',
            count: rightHereCount,
            icon: Icons.my_location_rounded,
            isSelected: selected == NearbyFilter.rightHere,
            isDark: isDark,
            onTap: () => onChanged(NearbyFilter.rightHere),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'All nearby',
            count: allCount,
            icon: Icons.groups_2_rounded,
            isSelected: selected == NearbyFilter.all,
            isDark: isDark,
            onTap: () => onChanged(NearbyFilter.all),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.count,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;
    final fg = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280));

    return Expanded(
      child: Material(
        color: isSelected
            ? accent
            : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? accent
                    : (isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFE8ECF4)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
