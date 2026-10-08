import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/auth/screens/splash_screen.dart';

void main() {
  testWidgets('the exit completes with the animation loaded', (tester) async {
    await tester.runAsync(precacheSplashLogo);

    var revealed = false;
    Widget host(bool ready) => MaterialApp(
      home: SplashScreen(ready: ready, onRevealComplete: () => revealed = true),
    );

    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(revealed, isFalse);

    await tester.pumpWidget(host(true));

    var elapsed = Duration.zero;
    const step = Duration(milliseconds: 16);
    while (elapsed < const Duration(seconds: 8) && !revealed) {
      await tester.pump(step);
      elapsed += step;
    }
    // ignore: avoid_print
    print('reveal completed after ${elapsed.inMilliseconds}ms');
    expect(revealed, isTrue, reason: 'splash never handed off to the app');
  });
}
