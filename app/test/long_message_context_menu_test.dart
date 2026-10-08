import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/message_limits.dart';
import 'package:talkmos/features/chats/widgets/chat_input_bar.dart';
import 'package:talkmos/features/chats/widgets/context_action_menu.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

void main() {
  const surface = Size(360, 720);

  List<List<ContextActionItem>> groups() => [
    [
      ContextActionItem(
        icon: Icons.reply_rounded,
        label: 'Reply',
        onTap: () {},
      ),
      ContextActionItem(icon: Icons.copy_rounded, label: 'Copy', onTap: () {}),
    ],
    [
      ContextActionItem(
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        onTap: () {},
      ),
    ],
  ];

  Future<void> openMenu(
    WidgetTester tester, {
    required Rect anchorRect,
    required double anchorHeight,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    ContextActionMenu.show(
      context: ctx,
      anchor: Container(
        height: anchorHeight,
        color: Colors.blue,
        alignment: Alignment.topLeft,
        child: const Text('BUBBLE'),
      ),
      anchorRect: anchorRect,
      alignEnd: false,
      isDark: false,
      onReact: (_) {},
      onMoreReactions: () {},
      actionGroups: groups(),
    );
    await tester.pumpAndSettle();
  }

  Rect screenOf(WidgetTester tester) =>
      tester.getRect(find.byType(MaterialApp));

  testWidgets('a bubble taller than the screen still gets a visible menu', (
    tester,
  ) async {
    // Mid-scroll through a long message: the bubble runs off both edges, so
    // neither one is a usable place to hang the card off.
    await openMenu(
      tester,
      anchorRect: const Rect.fromLTRB(16, -900, 344, 1400),
      anchorHeight: 2300,
    );

    final screen = screenOf(tester);
    for (final label in ['Reply', 'Copy', 'Delete']) {
      final row = tester.getRect(find.text(label));
      expect(row.top, greaterThanOrEqualTo(screen.top), reason: label);
      expect(row.bottom, lessThanOrEqualTo(screen.bottom), reason: label);
      expect(row.left, greaterThanOrEqualTo(screen.left), reason: label);
      expect(row.right, lessThanOrEqualTo(screen.right), reason: label);
    }
  });

  testWidgets('an oversized bubble preview scrolls instead of overflowing', (
    tester,
  ) async {
    await openMenu(
      tester,
      anchorRect: const Rect.fromLTRB(16, -900, 344, 1400),
      anchorHeight: 2300,
    );

    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a bubble that fits keeps the menu anchored to it', (
    tester,
  ) async {
    await openMenu(
      tester,
      anchorRect: const Rect.fromLTRB(16, 200, 300, 300),
      anchorHeight: 100,
    );

    // Below the bubble's own bottom edge, not re-centred on the screen.
    expect(tester.getRect(find.text('Reply')).top, greaterThan(300));
  });

  testWidgets('the composer stops at the message limit', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputBar(
              controller: controller,
              isTextEmpty: true,
              isDark: false,
              onSend: () {},
              onAttachment: () {},
              camera: () {},
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      'a' * (maxMessageChars + 50),
    );
    await tester.pump();

    expect(controller.text.length, maxMessageChars);
  });

  testWidgets('the limit never cuts an emoji in half', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputBar(
              controller: controller,
              isTextEmpty: true,
              isDark: false,
              onSend: () {},
              onAttachment: () {},
              camera: () {},
            ),
          ),
        ),
      ),
    );

    // One unit short of the cap, then a two-unit emoji: it has to be dropped
    // whole rather than truncated to a lone surrogate.
    await tester.enterText(
      find.byType(TextField),
      '${'a' * (maxMessageChars - 1)}😀',
    );
    await tester.pump();

    expect(controller.text.length, maxMessageChars - 1);
    expect(controller.text.contains('😀'), isFalse);
  });
}
