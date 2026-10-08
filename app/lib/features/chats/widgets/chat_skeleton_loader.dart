import 'package:flutter/material.dart';

/// Placeholder message list shown while a chat's history is loading.
class ChatSkeletonLoader extends StatelessWidget {
  final bool isDark;

  const ChatSkeletonLoader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 8,
      itemBuilder: (context, index) {
        // Alternate sides and vary widths so it reads like a real thread.
        final isMe = index % 3 == 0 || index % 5 == 0;
        final widthFactor = 0.4 + (index % 4) * 0.1;
        return _SkeletonBubble(
          isMe: isMe,
          widthFactor: widthFactor,
          isDark: isDark,
        );
      },
    );
  }
}

class _SkeletonBubble extends StatefulWidget {
  final bool isMe;
  final double widthFactor;
  final bool isDark;

  const _SkeletonBubble({
    required this.isMe,
    required this.widthFactor,
    required this.isDark,
  });

  @override
  State<_SkeletonBubble> createState() => _SkeletonBubbleState();
}

class _SkeletonBubbleState extends State<_SkeletonBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? const Color(0xFF000814)
        : const Color(0xFFE2E8F0);
    final shimmerColor = widget.isDark
        ? const Color(0xFF000E23)
        : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (_, __) {
            final color = Color.lerp(baseColor, shimmerColor, _animation.value);
            return Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * widget.widthFactor,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                      bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
