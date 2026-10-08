import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../models/friend_model.dart';

/// Friend's photo, or their first initial on a tinted circle when they have
/// no avatar set.
class FriendAvatar extends StatelessWidget {
  final FriendModel friend;
  final double radius;
  final Color primary;

  const FriendAvatar({
    super.key,
    required this.friend,
    required this.radius,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AvatarCircle(
      imageUrl: friend.avatarUrl,
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.12),
      fallback: Text(
        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
          color: primary,
        ),
      ),
    );
  }
}
