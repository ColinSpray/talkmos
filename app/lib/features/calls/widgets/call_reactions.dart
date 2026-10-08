import 'package:flutter/material.dart';
import 'call_theme_colors.dart';

class CallReaction {
  final int id;
  final String emoji;
  final double dx;
  const CallReaction({required this.id, required this.emoji, required this.dx});
}

/// A single emoji that rises and fades out over ~1.8s, positioned at a
/// horizontal fraction [dx] of the screen width.
class FloatingReactionWidget extends StatelessWidget {
  final String emoji;
  final double dx;
  const FloatingReactionWidget({
    super.key,
    required this.emoji,
    required this.dx,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Positioned(
          bottom: 40 + t * 260,
          left: dx * (width - 40),
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.8 + t * 0.4, child: child),
          ),
        );
      },
      child: Text(emoji, style: const TextStyle(fontSize: 32)),
    );
  }
}

/// Renders every currently-live [CallReaction] as a [FloatingReactionWidget].
/// Meant to sit in an [IgnorePointer] above the call content.
class ReactionOverlay extends StatelessWidget {
  final List<CallReaction> reactions;
  const ReactionOverlay({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: reactions
          .map(
            (r) => FloatingReactionWidget(
              key: ValueKey(r.id),
              emoji: r.emoji,
              dx: r.dx,
            ),
          )
          .toList(),
    );
  }
}

/// Quick emoji picker row shown above the utility bar when the reactions
/// button is toggled on.
class ReactionPickerRow extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onPick;
  const ReactionPickerRow({
    super.key,
    required this.isDark,
    required this.onPick,
  });

  static const _emojis = ['❤️', '👍', '👏', '😂'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: callPillBg(isDark),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _emojis
            .map(
              (e) => GestureDetector(
                onTap: () => onPick(e),
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            )
            .toList(),
      ),
    );
  }
}
