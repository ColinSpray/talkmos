import 'package:flutter/material.dart';

class NearbyConsentSheet extends StatelessWidget {
  const NearbyConsentSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NearbyConsentSheet(),
    );
    return accepted == true;
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
          const SizedBox(height: 20),
          Text(
            'Turn on Nearby?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _Point(
            icon: Icons.person_outline_rounded,
            text:
                'Your name and profile photo will be visible to other '
                'Talkmos users near you.',
            isDark: isDark,
          ),
          _Point(
            icon: Icons.schedule_rounded,
            text:
                'People near you can find you for up to 30 minutes after '
                'you use Talkmos — not only while this screen is open.',
            isDark: isDark,
          ),
          _Point(
            icon: Icons.my_location_outlined,
            text:
                'Your approximate area is used to find people, never your '
                'exact location, and it is never shown to anyone. Your last '
                'area is kept so you can still be found while Talkmos is '
                'closed, and is deleted the moment you turn Nearby off.',
            isDark: isDark,
          ),
          _Point(
            icon: Icons.toggle_off_outlined,
            text: 'Turn Nearby off any time and you disappear immediately.',
            isDark: isDark,
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
              child: const Text('Turn on'),
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

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _Point({required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
