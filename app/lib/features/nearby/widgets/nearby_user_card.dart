import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/nearby_user_model.dart';

class NearbyUserCard extends StatelessWidget {
  final NearbyUserModel user;
  final VoidCallback onTap;
  final VoidCallback onReport;

  const NearbyUserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onReport,
  });

  bool get _isRightHere => user.tier == NearbyTier.rightHere;

  String get _tierLabel => switch (user.tier) {
    NearbyTier.rightHere => 'Right here',
    NearbyTier.veryClose => 'Very close',
    NearbyTier.nearby => 'Nearby recently',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).primaryColor;

    return Material(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onReport,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isRightHere
                  ? accent.withValues(alpha: 0.55)
                  : (isDark
                        ? const Color(0xFF262626)
                        : const Color(0xFFE8ECF4)),
              width: _isRightHere ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(user: user, isDark: isDark, accent: accent),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                      ),
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, size: 15, color: accent),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _TierChip(
                label: _tierLabel,
                isRightHere: _isRightHere,
                isDark: isDark,
                accent: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final String label;
  final bool isRightHere;
  final bool isDark;
  final Color accent;

  const _TierChip({
    required this.label,
    required this.isRightHere,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isRightHere
            ? accent.withValues(alpha: isDark ? 0.18 : 0.10)
            : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRightHere) ...[
            Icon(Icons.my_location_rounded, size: 12, color: accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isRightHere ? FontWeight.w600 : FontWeight.w500,
              color: isRightHere ? accent : muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final NearbyUserModel user;
  final bool isDark;
  final Color accent;

  const _Avatar({
    required this.user,
    required this.isDark,
    required this.accent,
  });

  // Large on purpose: the entire premise is recognising a face you just saw,
  // so the photo is the content and the name is the caption.
  static const double _size = 92;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF262626) : const Color(0xFFE8ECF4),
      ),
      alignment: Alignment.center,
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
        ),
      ),
    );

    final avatar = user.avatarUrl.isEmpty
        ? placeholder
        : ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.avatarUrl,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
          );

    if (user.tier != NearbyTier.rightHere) return avatar;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: avatar,
        ),
      ],
    );
  }
}
