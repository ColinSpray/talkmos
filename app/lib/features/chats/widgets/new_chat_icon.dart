import 'package:flutter/material.dart';

class NewChatIcon extends StatelessWidget {
  /// Overall width/height of the bubble.
  final double size;

  /// Bubble and badge fill.
  final Color color;

  /// Surface the icon sits on — used for the ring around the badge and for
  /// the "+" itself, so both read as cut-outs.
  final Color backgroundColor;

  const NewChatIcon({
    super.key,
    this.size = 30,
    this.color = Colors.white,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.58;
    final ringWidth = size * 0.085;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.chat_bubble_rounded, size: size, color: color),
          Positioned(
            // Pushed past the glyph's edge so the badge reads as sitting on
            // the bubble's corner rather than inside it.
            right: -badgeSize * 0.34,
            bottom: -badgeSize * 0.22,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: backgroundColor, width: ringWidth),
              ),
              child: Icon(
                Icons.add_rounded,
                size: badgeSize * 0.66,
                color: backgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
