import 'package:flutter/material.dart';

/// The message bubble outline, with the little pointed tail at the top outer
/// corner that reads as "chat bubble" at a glance.
///
/// The tail's width is reserved on every bubble whether or not one is drawn,
/// so a run of messages keeps a straight edge and only the first of the run
/// carries the point.
class BubbleShape extends ShapeBorder {
  final bool isMe;
  final bool showTail;
  final double radius;
  final double tailWidth;
  final double tailHeight;

  const BubbleShape({
    required this.isMe,
    required this.showTail,
    this.radius = 8,
    this.tailWidth = 7,
    this.tailHeight = 13,
  });

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(left: isMe ? 0 : tailWidth, right: isMe ? tailWidth : 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final corner = Radius.circular(radius);
    final left = isMe ? rect.left : rect.left + tailWidth;
    final right = isMe ? rect.right - tailWidth : rect.right;

    final body = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          left,
          rect.top,
          right,
          rect.bottom,
          // The corner the tail grows out of is square, so the two shapes
          // merge into one outline rather than showing a seam.
          topLeft: (!isMe && showTail) ? Radius.zero : corner,
          topRight: (isMe && showTail) ? Radius.zero : corner,
          bottomLeft: corner,
          bottomRight: corner,
        ),
      );

    if (!showTail) return body;

    final tail = Path();
    if (isMe) {
      tail
        ..moveTo(right, rect.top)
        ..lineTo(rect.right, rect.top)
        ..quadraticBezierTo(
          right + tailWidth * 0.4,
          rect.top + tailHeight * 0.55,
          right,
          rect.top + tailHeight,
        )
        ..close();
    } else {
      tail
        ..moveTo(left, rect.top)
        ..lineTo(rect.left, rect.top)
        ..quadraticBezierTo(
          left - tailWidth * 0.4,
          rect.top + tailHeight * 0.55,
          left,
          rect.top + tailHeight,
        )
        ..close();
    }

    return Path.combine(PathOperation.union, body, tail);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => BubbleShape(
    isMe: isMe,
    showTail: showTail,
    radius: radius * t,
    tailWidth: tailWidth * t,
    tailHeight: tailHeight * t,
  );

  @override
  bool operator ==(Object other) =>
      other is BubbleShape &&
      other.isMe == isMe &&
      other.showTail == showTail &&
      other.radius == radius &&
      other.tailWidth == tailWidth &&
      other.tailHeight == tailHeight;

  @override
  int get hashCode =>
      Object.hash(isMe, showTail, radius, tailWidth, tailHeight);
}
