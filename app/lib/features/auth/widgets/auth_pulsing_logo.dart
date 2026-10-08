import 'package:flutter/material.dart';

class AuthPulsingLogo extends StatefulWidget {
  final Widget child;
  final double areaSize;
  final double ringBaseSize;
  final double ringMaxSize;
  final Color accent;
  final bool isDark;

  const AuthPulsingLogo({
    super.key,
    required this.child,
    required this.areaSize,
    required this.ringBaseSize,
    required this.ringMaxSize,
    required this.accent,
    required this.isDark,
  });

  @override
  State<AuthPulsingLogo> createState() => _AuthPulsingLogoState();
}

class _AuthPulsingLogoState extends State<AuthPulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.areaSize,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _pulsingRing(delay: 0.0),
                _pulsingRing(delay: 0.5),
                _staticRing(),
                child!,
              ],
            );
          },
          child: widget.child,
        ),
      ),
    );
  }

  Widget _pulsingRing({required double delay}) {
    final t = (_controller.value + delay) % 1.0;
    final curved = Curves.easeOut.transform(t);

    final size =
        widget.ringBaseSize +
        (widget.ringMaxSize - widget.ringBaseSize) * curved;
    final opacity = (1.0 - curved).clamp(0.0, 1.0) * 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.5)
                : widget.accent.withValues(alpha: 0.5),
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _staticRing() {
    return Container(
      width: widget.ringBaseSize,
      height: widget.ringBaseSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE7E5F5),
          width: 1,
        ),
      ),
    );
  }
}
