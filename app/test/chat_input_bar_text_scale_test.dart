import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/widgets/chat_input_bar.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

void main() {
  // A narrow phone: the emoji/attach/camera buttons are fixed-width, so this
  // is where the field gets squeezed hardest.
  const surface = Size(360, 720);

  Widget host(double textScale, TextEditingController controller) => MediaQuery(
    data: MediaQueryData(
      size: surface,
      textScaler: TextScaler.linear(textScale),
    ),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChatInputBar(
            controller: controller,
            isTextEmpty: controller.text.isEmpty,
            isDark: false,
            onSend: () {},
            onAttachment: () {},
            camera: () {},
          ),
        ),
      ),
    ),
  );

  Future<void> pumpAt(WidgetTester tester, double textScale) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(textScale, controller));
    await tester.pumpAndSettle();
  }

  // One empty line of the field, as laid out at the current scale.
  double lineHeight(WidgetTester tester) =>
      tester.getSize(find.byType(EditableText)).height;

  double hintHeight(WidgetTester tester) =>
      tester.getSize(find.text('Type a message…')).height;

  testWidgets('the placeholder stays on one line at a large font scale', (
    tester,
  ) async {
    await pumpAt(tester, 2.0);

    expect(hintHeight(tester), lessThanOrEqualTo(lineHeight(tester)));
  });

  testWidgets('the placeholder stays on one line at the default font scale', (
    tester,
  ) async {
    await pumpAt(tester, 1.0);

    expect(hintHeight(tester), lessThanOrEqualTo(lineHeight(tester)));
  });

  testWidgets('text scale stops growing the bar past the clamp', (
    tester,
  ) async {
    await pumpAt(tester, 1.3);
    final atClamp = lineHeight(tester);

    await pumpAt(tester, 3.0);

    expect(lineHeight(tester), atClamp);
  });

  testWidgets('a large font trades the camera shortcut for field width', (
    tester,
  ) async {
    await pumpAt(tester, 1.0);
    final normalWidth = tester.getSize(find.byType(TextField)).width;
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

    await pumpAt(tester, 2.0);

    // Still reachable from the attachment sheet — this only drops the
    // duplicate shortcut.
    expect(tester.getSize(find.byType(TextField)).width, normalWidth + 48);
  });
}
