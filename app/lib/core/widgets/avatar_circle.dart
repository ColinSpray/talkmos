import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/media_cache_service.dart';

/// Someone's photo on a tinted circle, falling back to [fallback] — when they
/// have no photo, and when the one they have fails to load. A dead URL would
/// otherwise leave an empty circle where their initial should be.
class AvatarCircle extends StatefulWidget {
  const AvatarCircle({
    super.key,
    required this.imageUrl,
    required this.radius,
    required this.backgroundColor,
    required this.fallback,
    this.foregroundColor,
  });

  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final Color? foregroundColor;

  /// Shown in place of the photo — usually the first initial, or a group icon.
  final Widget fallback;

  @override
  State<AvatarCircle> createState() => _AvatarCircleState();
}

class _AvatarCircleState extends State<AvatarCircle> {
  bool _failed = false;

  @override
  void didUpdateWidget(AvatarCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _failed = false;
  }

  void _onError(Object error, StackTrace? stack) {
    // The failure can arrive mid-build, straight out of the cache.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl ?? '';
    final showPhoto = url.isNotEmpty && !_failed;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      backgroundImage: showPhoto
          ? CachedNetworkImageProvider(
              url,
              cacheManager: MediaCacheService.manager,
            )
          : null,
      onBackgroundImageError: showPhoto ? _onError : null,
      child: showPhoto ? null : widget.fallback,
    );
  }
}
