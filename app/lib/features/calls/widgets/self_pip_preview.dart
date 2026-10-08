import 'package:flutter/material.dart';

class SelfPipPreview extends StatefulWidget {
  final Size screenSize;
  final double topPadding;

  final double bottomSafeZone;

  final Widget? videoChild;
  final VoidCallback onSwitchCamera;

  /// Tapping the tile swaps it with the full-screen view (WhatsApp-style).
  final VoidCallback? onTap;

  /// Off while the tile shows the *other* side, where flipping means nothing.
  final bool showSwitchCamera;

  const SelfPipPreview({
    super.key,
    required this.screenSize,
    required this.topPadding,
    required this.bottomSafeZone,
    required this.videoChild,
    required this.onSwitchCamera,
    this.onTap,
    this.showSwitchCamera = true,
  });

  @override
  State<SelfPipPreview> createState() => _SelfPipPreviewState();
}

class _SelfPipPreviewState extends State<SelfPipPreview> {
  static const _width = 100.0;
  static const _height = 140.0;

  Offset? _position;

  Offset _clamp(Offset raw) {
    final maxX = (widget.screenSize.width - _width - 12.0).clamp(
      12.0,
      double.infinity,
    );
    final maxY = (widget.screenSize.height - _height - widget.bottomSafeZone)
        .clamp(widget.topPadding + 60.0, double.infinity);
    return Offset(
      raw.dx.clamp(12.0, maxX),
      raw.dy.clamp(widget.topPadding + 60.0, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPosition = Offset(
      widget.screenSize.width - _width - 20.0,
      widget.topPadding + 60.0,
    );
    final position = _position ?? defaultPosition;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanUpdate: (details) {
          setState(() => _position = _clamp(position + details.delta));
        },
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IgnorePointer(
                  child:
                      widget.videoChild ??
                      Container(color: const Color(0xFF000814)),
                ),
              ),
              if (widget.showSwitchCamera)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: GestureDetector(
                    onTap: widget.onSwitchCamera,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flip_camera_ios_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
