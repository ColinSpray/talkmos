import 'package:flutter/material.dart';
import 'story_editor_models.dart';

class StoryOverlayLayer extends StatelessWidget {
  final List<StoryTextItem> textItems;
  final List<StoryStickerItem> stickerItems;

  /// Called after a drag mutates an item's position in place, so the parent
  /// can rebuild.
  final VoidCallback onChanged;
  final ValueChanged<int> onTextRemoved;
  final ValueChanged<int> onStickerRemoved;

  const StoryOverlayLayer({
    super.key,
    required this.textItems,
    required this.stickerItems,
    required this.onChanged,
    required this.onTextRemoved,
    required this.onStickerRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < textItems.length; i++) _buildText(size, i),
            for (var i = 0; i < stickerItems.length; i++)
              _buildSticker(size, i),
          ],
        );
      },
    );
  }

  void _drag(
    Size size,
    Offset Function() getPosition,
    void Function(Offset) setPosition,
    Offset delta,
  ) {
    final current = getPosition();
    setPosition(
      Offset(
        (current.dx + delta.dx / size.width).clamp(0.0, 1.0),
        (current.dy + delta.dy / size.height).clamp(0.0, 1.0),
      ),
    );
    onChanged();
  }

  // A plain black87 circle blends into a black or near-black photo — the
  // white border keeps the badge visible no matter what's underneath.
  Widget _deleteBadge(VoidCallback onTap) {
    return Positioned(
      top: -10,
      right: -10,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
        ),
      ),
    );
  }

  Widget _buildText(Size size, int index) {
    final item = textItems[index];
    return Positioned(
      left: (item.position.dx * size.width).clamp(0.0, size.width),
      top: (item.position.dy * size.height).clamp(0.0, size.height),
      child: GestureDetector(
        onPanUpdate: (details) => _drag(
          size,
          () => item.position,
          (p) => item.position = p,
          details.delta,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                item.text,
                style: TextStyle(
                  color: item.color,
                  fontSize: item.fontSize * size.width,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _deleteBadge(() => onTextRemoved(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildSticker(Size size, int index) {
    final item = stickerItems[index];
    final emojiSize = 0.14 * size.width * item.scale;
    return Positioned(
      left: (item.position.dx * size.width).clamp(0.0, size.width),
      top: (item.position.dy * size.height).clamp(0.0, size.height),
      child: GestureDetector(
        onPanUpdate: (details) => _drag(
          size,
          () => item.position,
          (p) => item.position = p,
          details.delta,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(item.emoji, style: TextStyle(fontSize: emojiSize)),
            _deleteBadge(() => onStickerRemoved(index)),
          ],
        ),
      ),
    );
  }
}
