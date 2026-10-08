import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:talkmos/features/chats/widgets/chat_header.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool isOnline = false,
    bool isTyping = false,
    DateTime? lastSeenAt,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: ChatHeader(
            peerName: 'Rahul',
            peerAvatarUrl: '',
            isDark: false,
            isOnline: isOnline,
            isTyping: isTyping,
            lastSeenAt: lastSeenAt,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a connected peer reads as online', (tester) async {
    await pump(tester, isOnline: true, lastSeenAt: DateTime.now());

    expect(find.text('online'), findsOneWidget);
  });

  testWidgets('today keeps the clock time without a date', (tester) async {
    final at = DateTime.now().subtract(const Duration(hours: 2));
    await pump(tester, lastSeenAt: at);

    expect(
      find.text('last seen today at ${DateFormat.jm().format(at)}'),
      findsOneWidget,
    );
  });

  testWidgets('yesterday is named rather than dated', (tester) async {
    final now = DateTime.now();
    // Anchored to midday so the subtraction cannot skip a calendar day.
    final at = DateTime(
      now.year,
      now.month,
      now.day,
      12,
    ).subtract(const Duration(days: 1));
    await pump(tester, lastSeenAt: at);

    expect(
      find.text('last seen yesterday at ${DateFormat.jm().format(at)}'),
      findsOneWidget,
    );
  });

  testWidgets('anything older carries the date', (tester) async {
    final at = DateTime(2026, 8, 14, 9, 15);
    await pump(tester, lastSeenAt: at);

    expect(
      find.text('last seen 14/08/2026 at ${DateFormat.jm().format(at)}'),
      findsOneWidget,
    );
  });

  testWidgets('a clock skewed into the future does not read as a date', (
    tester,
  ) async {
    final at = DateTime.now().add(const Duration(minutes: 20));
    await pump(tester, lastSeenAt: at);

    expect(
      find.text('last seen today at ${DateFormat.jm().format(at)}'),
      findsOneWidget,
    );
  });

  testWidgets('typing wins over both', (tester) async {
    await pump(tester, isTyping: true, lastSeenAt: DateTime(2026, 8, 14));

    expect(find.textContaining('last seen'), findsNothing);
    expect(find.text('online'), findsNothing);
  });

  testWidgets('a peer who hides last seen gets no subtitle at all', (
    tester,
  ) async {
    await pump(tester);

    expect(find.textContaining('last seen'), findsNothing);
    expect(find.text('online'), findsNothing);
    expect(find.text('Rahul'), findsOneWidget);
  });
}
