import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipe;

  const SwipeToReply({super.key, required this.child, this.onSwipe});

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  bool _isThresholdPassed = false;

  static const double _maxDragOffset = 80.0;
  static const double _triggerThreshold = 45.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final double newOffset = _dragOffset + details.delta.dx;
    if (newOffset >= 0) {
      final double clampedOffset = newOffset.clamp(0.0, _maxDragOffset);
      final bool passed = clampedOffset >= _triggerThreshold;

      if (passed && !_isThresholdPassed) {
        HapticFeedback.lightImpact();
      }

      setState(() {
        _dragOffset = clampedOffset;
        _isThresholdPassed = passed;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isThresholdPassed) {
      widget.onSwipe?.call();
    }
    _animateBack();
  }

  void _animateBack() {
    final double start = _dragOffset;
    _controller.reset();
    final Animation<double> animation = Tween<double>(
      begin: start,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });
    _controller.forward();
    _isThresholdPassed = false;
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_dragOffset / _triggerThreshold).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Behind layer: contains the reply icon
        if (widget.onSwipe != null)
          Positioned(
            left: 10,
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: progress * (_isThresholdPassed ? 1.15 : 0.9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isThresholdPassed
                        ? Theme.of(context).primaryColor
                        : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.reply_rounded,
                    size: 20,
                    color: _isThresholdPassed
                        ? Colors.white
                        : (isDark
                              ? Colors.white70
                              : Theme.of(context).primaryColor),
                  ),
                ),
              ),
            ),
          ),
        // Sliding child layer (the chat bubble)
        Transform.translate(
          offset: Offset(_dragOffset, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: widget.onSwipe == null
                ? null
                : _onHorizontalDragUpdate,
            onHorizontalDragEnd: widget.onSwipe == null
                ? null
                : _onHorizontalDragEnd,
            behavior: HitTestBehavior.translucent,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
