import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/widgets/bubble_shape.dart';

void main() {
  const rect = Rect.fromLTWH(0, 0, 200, 60);

  group('the tail', () {
    test('fills the outer top corner on the first bubble of a run', () {
      final incoming = const BubbleShape(
        isMe: false,
        showTail: true,
      ).getOuterPath(rect);
      final outgoing = const BubbleShape(
        isMe: true,
        showTail: true,
      ).getOuterPath(rect);

      // A point in the reserved gutter, right against the top edge — inside
      // the outline only because the tail is drawn there.
      expect(incoming.contains(const Offset(2, 1)), isTrue);
      expect(outgoing.contains(const Offset(198, 1)), isTrue);
    });

    test('is absent on the rest of the run', () {
      final incoming = const BubbleShape(
        isMe: false,
        showTail: false,
      ).getOuterPath(rect);
      final outgoing = const BubbleShape(
        isMe: true,
        showTail: false,
      ).getOuterPath(rect);

      expect(incoming.contains(const Offset(2, 1)), isFalse);
      expect(outgoing.contains(const Offset(198, 1)), isFalse);
    });

    test('only ever grows on the sender\'s own side', () {
      final incoming = const BubbleShape(
        isMe: false,
        showTail: true,
      ).getOuterPath(rect);
      // An incoming tail must not appear on the right, where the reserved
      // gutter belongs to outgoing bubbles.
      expect(incoming.contains(const Offset(198, 1)), isFalse);
    });
  });

  group('the reserved gutter', () {
    test('sits on the side the tail grows from', () {
      expect(
        const BubbleShape(isMe: false, showTail: true).dimensions,
        const EdgeInsets.only(left: 7),
      );
      expect(
        const BubbleShape(isMe: true, showTail: true).dimensions,
        const EdgeInsets.only(right: 7),
      );
    });

    test('is held whether or not a tail is drawn', () {
      // This is what keeps a run's edge straight — a tail-less bubble is
      // inset exactly as far as the one above it that has the point.
      expect(
        const BubbleShape(isMe: false, showTail: false).dimensions,
        const BubbleShape(isMe: false, showTail: true).dimensions,
      );
    });

    test('keeps the body off the gutter it reserved', () {
      final path = const BubbleShape(
        isMe: false,
        showTail: false,
      ).getOuterPath(rect);
      // Mid-height, inside the gutter: body territory starts after it.
      expect(path.contains(const Offset(3, 30)), isFalse);
      expect(path.contains(const Offset(9, 30)), isTrue);
    });
  });

  test('equal shapes compare equal so the decoration is not rebuilt', () {
    const a = BubbleShape(isMe: true, showTail: true);
    const b = BubbleShape(isMe: true, showTail: true);
    const c = BubbleShape(isMe: true, showTail: false);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
