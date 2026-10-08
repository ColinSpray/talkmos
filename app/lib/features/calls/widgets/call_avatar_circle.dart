import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/media_cache_service.dart';

/// The ringed avatar shown in the middle of a 1:1 call — the peer's photo, or
/// their initial when there is none (or it fails to load).
class CallAvatarCircle extends StatelessWidget {
  final bool isDark;
  final String? avatarUrl;
  final String initials;
  final Color borderColor;
  final double size;

  const CallAvatarCircle({
    super.key,
    required this.isDark,
    required this.avatarUrl,
    required this.initials,
    required this.borderColor,
    this.size = 130,
  });

  @override
  Widget build(BuildContext context) {
    final initialsText = Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.37,
          color: isDark ? Colors.white : Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF000814) : const Color(0xFFE8F2FF),
        border: Border.all(color: borderColor, width: 8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                cacheManager: MediaCacheService.manager,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => initialsText,
              )
            : initialsText,
      ),
    );
  }
}
