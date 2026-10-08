import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/auth/screens/splash_screen.dart';

void main() {
  // Mirrors the controller durations in splash_screen.dart.
  const intro = Duration(milliseconds: 850);
  const reveal = Duration(milliseconds: 560);

  Widget host({required bool ready, required VoidCallback onDone}) =>
      MaterialApp(
        home: SplashScreen(ready: ready, onRevealComplete: onDone),
      );

  /// Pumps frames until [predicate] holds, and reports how long that took.
  /// Returns null if it never held within [limit].
  ///
  /// Stepping frame by frame rather than pumping exact durations, because the
  /// reveal's ticker is started from inside the intro's tick — its first frame
  /// only records a start time, so an exact-duration pump lands a frame short.
  Future<Duration?> advanceUntil(
    WidgetTester tester,
    bool Function() predicate, {
    required Duration limit,
  }) async {
    const step = Duration(milliseconds: 16);
    var elapsed = Duration.zero;
    while (elapsed < limit) {
      if (predicate()) return elapsed;
      await tester.pump(step);
      elapsed += step;
    }
    return predicate() ? elapsed : null;
  }

  testWidgets('idles indefinitely while the app is still booting', (
    tester,
  ) async {
    var revealed = false;
    await tester.pumpWidget(host(ready: false, onDone: () => revealed = true));

    await tester.pump(intro + reveal + const Duration(seconds: 3));

    expect(revealed, isFalse);
  });

  testWidgets('plays the intro in full even when the app is ready at once', (
    tester,
  ) async {
    var revealed = false;
    // `ready` true on the very first frame — a boot that resolved from cache
    // before the splash was even built.
    await tester.pumpWidget(host(ready: true, onDone: () => revealed = true));

    final at = await advanceUntil(
      tester,
      () => revealed,
      limit: const Duration(seconds: 5),
    );

    expect(at, isNotNull, reason: 'the reveal never completed');
    expect(
      at,
      greaterThanOrEqualTo(intro + reveal),
      reason: 'the intro or the reveal was cut short',
    );
  });

  testWidgets('reveals once ready arrives after the intro has landed', (
    tester,
  ) async {
    var revealed = false;
    void onDone() => revealed = true;

    await tester.pumpWidget(host(ready: false, onDone: onDone));
    await tester.pump(intro + const Duration(milliseconds: 500));
    expect(revealed, isFalse);

    await tester.pumpWidget(host(ready: true, onDone: onDone));
    final at = await advanceUntil(
      tester,
      () => revealed,
      limit: const Duration(seconds: 5),
    );

    expect(at, isNotNull, reason: 'the reveal never completed');
    expect(
      at,
      greaterThanOrEqualTo(reveal),
      reason: 'the reveal was cut short',
    );
  });
}
