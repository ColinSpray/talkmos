import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/widgets/group_profile_menu_sheet.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

void main() {
  Future<int> openMenu(WidgetTester tester, {required bool isOwner}) async {
    var deletes = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showGroupProfileMenuSheet(
                  context: context,
                  isDark: false,
                  textColor: Colors.black,
                  onEditInfo: () {},
                  onLeaveGroup: () {},
                  onDeleteGroup: isOwner ? () => deletes++ : null,
                ),
                child: const Text('menu'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('menu'));
    await tester.pumpAndSettle();
    return deletes;
  }

  testWidgets('the owner is offered Delete Group', (tester) async {
    await openMenu(tester, isOwner: true);

    expect(find.text('Delete Group'), findsOneWidget);
    expect(find.text('Leave Group'), findsOneWidget);
  });

  testWidgets('a non-owner is not', (tester) async {
    await openMenu(tester, isOwner: false);

    expect(find.text('Delete Group'), findsNothing);
    // Leaving is still theirs to do.
    expect(find.text('Leave Group'), findsOneWidget);
  });

  testWidgets('tapping Delete Group closes the menu and calls back', (
    tester,
  ) async {
    var deletes = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showGroupProfileMenuSheet(
                  context: context,
                  isDark: false,
                  textColor: Colors.black,
                  onEditInfo: () {},
                  onLeaveGroup: () {},
                  onDeleteGroup: () => deletes++,
                ),
                child: const Text('menu'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete Group'));
    await tester.pumpAndSettle();

    expect(deletes, 1);
    expect(find.text('Delete Group'), findsNothing);
  });
}
