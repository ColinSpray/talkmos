import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/core/widgets/avatar_circle.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('falls back to the initial without a photo', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AvatarCircle(
          imageUrl: null,
          radius: 20,
          backgroundColor: Colors.blue,
          fallback: Text('A'),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isNull);
  });

  testWidgets('carries an error handler while showing a photo', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AvatarCircle(
          imageUrl: 'https://example.invalid/gone.jpg',
          radius: 20,
          backgroundColor: Colors.blue,
          fallback: Text('B'),
        ),
      ),
    );

    // The photo comes first; the handler is what swaps in the initial when
    // the URL turns out to be dead.
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isNotNull);
    expect(avatar.onBackgroundImageError, isNotNull);
    expect(find.text('B'), findsNothing);
  });
}
