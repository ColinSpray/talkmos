import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/calls/utils/call_title.dart';

void main() {
  group('callTitleFor', () {
    test('names whoever is still on the call', () {
      // A called B and C, then hung up. On B's screen the only remote left
      // is C — and it used to keep saying "A".
      expect(callTitleFor(['C'], fallback: 'A'), 'C');
    });

    test('lists everyone else while they are all still there', () {
      expect(callTitleFor(['C', 'A'], fallback: 'A'), 'A, C');
    });

    test('falls back to the dialled name before anyone joins', () {
      expect(callTitleFor(const [], fallback: 'B'), 'B');
    });

    test('is stable regardless of participant order', () {
      expect(callTitleFor(['C', 'A', 'B']), callTitleFor(['B', 'C', 'A']));
    });

    test('ignores blank names rather than printing empty separators', () {
      expect(callTitleFor(['B', '', '   ', 'C']), 'B, C');
    });

    test('an empty room with no fallback is empty, not "null"', () {
      expect(callTitleFor(const []), '');
      expect(callTitleFor(const [], fallback: '  '), '');
    });
  });
}
