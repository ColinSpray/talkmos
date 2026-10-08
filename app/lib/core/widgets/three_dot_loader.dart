import 'package:flutter/material.dart';

class ThreeDotLoader extends StatefulWidget {
  const ThreeDotLoader({
    super.key,
    this.color = Colors.white,
    this.size = 8,
    this.spacing = 5,
  });

  final Color color;
  final double size;
  final double spacing;

  @override
  State<ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: _Dot(
            controller: _controller,
            delay: i * 0.2,
            color: widget.color,
            size: widget.size,
          ),
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.controller,
    required this.delay,
    required this.color,
    required this.size,
  });

  final AnimationController controller;
  final double delay;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final interval = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, delay + 0.6, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: interval,
      builder: (context, child) {
        // Rises then falls back within its slice of the cycle rather than a
        // one-way tween, so each lap loops without a visible snap.
        final bounce = interval.value < 0.5
            ? interval.value * 2
            : (1 - interval.value) * 2;
        return Transform.scale(
          scale: 0.5 + 0.5 * bounce,
          child: Opacity(opacity: 0.4 + 0.6 * bounce, child: child),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
