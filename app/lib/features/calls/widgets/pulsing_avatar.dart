import 'package:flutter/material.dart';

class PulsingAvatar extends StatelessWidget {
  final Animation<double> animation;
  final Widget avatar;
  final bool showPulse;
  final Color glowColor;

  static const double _baseSize = 130;
  static const double _maxGrowth = 34;
  static const double maxSize = _baseSize + _maxGrowth;

  const PulsingAvatar({
    super.key,
    required this.animation,
    required this.avatar,
    required this.showPulse,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxSize,
      height: maxSize,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = showPulse ? animation.value : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (showPulse)
                Container(
                  width: _baseSize + t * _maxGrowth,
                  height: _baseSize + t * _maxGrowth,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glowColor.withValues(alpha: (1 - t) * 0.25),
                  ),
                ),
              child!,
            ],
          );
        },
        child: avatar,
      ),
    );
  }
}
