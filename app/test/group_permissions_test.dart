import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/utils/group_permissions.dart';
import 'package:talkmos/features/chats/widgets/group_members_sheet.dart';
import 'package:talkmos/features/chats/widgets/group_profile_header.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

void main() {
  bool allowed(String setting, String role) => groupActionAllowed(
    permissions: {'addMembers': setting},
    role: role,
    action: 'addMembers',
  );

  group('groupActionAllowed', () {
    test("'admins' shuts out plain members", () {
      expect(allowed('admins', 'member'), isFalse);
      expect(allowed('admins', 'admin'), isTrue);
      expect(allowed('admins', 'owner'), isTrue);
    });

    test("'everyone' lets anyone through", () {
      expect(allowed('everyone', 'member'), isTrue);
      expect(allowed('everyone', 'admin'), isTrue);
    });

    test('an unset action is open, matching the server fallback', () {
      expect(
        groupActionAllowed(
          permissions: const {},
          role: 'member',
          action: 'editInfo',
        ),
        isTrue,
      );
    });

    test('each action is decided by its own setting', () {
      const permissions = {'addMembers': 'admins', 'editInfo': 'everyone'};
      expect(
        groupActionAllowed(
          permissions: permissions,
          role: 'member',
          action: 'addMembers',
        ),
        isFalse,
      );
      expect(
        groupActionAllowed(
          permissions: permissions,
          role: 'member',
          action: 'editInfo',
        ),
        isTrue,
      );
    });
  });

  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('the group photo is not tappable without edit rights', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const GroupProfileHeader(
          avatarUrl: null,
          isUploadingImage: false,
          name: 'Trip',
          memberCount: 3,
          description: '',
          isDark: false,
          textColor: Colors.black,
          primary: Colors.blue,
        ),
      ),
    );

    // The camera badge is the affordance; without it there's nothing to tap.
    expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
  });

  testWidgets('the group photo is tappable with them', (tester) async {
    await tester.pumpWidget(
      host(
        GroupProfileHeader(
          avatarUrl: null,
          isUploadingImage: false,
          onAvatarTap: () {},
          name: 'Trip',
          memberCount: 3,
          description: '',
          isDark: false,
          textColor: Colors.black,
          primary: Colors.blue,
        ),
      ),
    );

    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
  });

  group('the members sheet', () {
    final members = [
      {
        'userId': {'_id': 'u1', 'name': 'asha'},
        'role': 'member',
      },
      {
        'userId': {'_id': 'u2', 'name': 'ravi'},
        'role': 'owner',
      },
    ];

    Future<void> openSheet(
      WidgetTester tester, {
      required bool canRemove,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showGroupMembersSheet(
                    context: context,
                    members: members,
                    isDark: false,
                    textColor: Colors.black,
                    onRemoveMember: canRemove ? (_, _) {} : null,
                  ),
                  child: const Text('members'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('members'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers no remove button to a plain member', (tester) async {
      await openSheet(tester, canRemove: false);

      expect(find.byIcon(Icons.person_remove_rounded), findsNothing);
      expect(find.text('Asha'), findsOneWidget);
    });

    testWidgets('offers one to an admin, but never for the owner', (
      tester,
    ) async {
      await openSheet(tester, canRemove: true);

      // Two members listed, and only the non-owner is removable.
      expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);
    });
  });
}
