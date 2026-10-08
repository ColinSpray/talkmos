import 'package:flutter/material.dart';

class PermissionSheet extends StatelessWidget {
  const PermissionSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;

  /// Returns true when the user asked to be taken to Settings.
  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    String actionLabel = 'Open Settings',
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PermissionSheet(
        icon: icon,
        title: title,
        body: body,
        actionLabel: actionLabel,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFE8ECF4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(actionLabel),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Not now',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
