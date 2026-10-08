import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/features/stories/screens/story_viewer_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/story_group_model.dart';
import 'package:talkmos/models/story_model.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/providers/auth_provider.dart';
import 'package:talkmos/providers/story_provider.dart';

/// Keeps the viewer off the network — the screen reports each story as viewed
/// as it opens it.
class _OfflineStoryProvider extends StoryProvider {
  _OfflineStoryProvider({this.deleteSucceeds = true});

  final bool deleteSucceeds;
  final List<String> deleted = [];

  @override
  Future<void> viewStory(String storyId) async {}

  @override
  Future<bool> deleteStory(String storyId) async {
    deleted.add(storyId);
    return deleteSucceeds;
  }
}

/// Signs in as [id], so the viewer can tell whose status it is showing.
class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider(this.id);

  final String id;

  @override
  UserModel? get user => UserModel(id: id, name: 'me');
}

void main() {
  StoryModel story(String id) => StoryModel(
    id: id,
    userId: 'u1',
    mediaUrl: 'https://cdn.example/$id.jpg',
    type: 'image',
    viewsCount: 0,
    isViewed: false,
    createdAt: DateTime(2026, 1, 1, id == 'a' ? 1 : 2),
    expiresAt: DateTime(2026, 1, 2),
  );

  final defaultGroup = StoryGroupModel(
    user: UserModel(id: 'u1', name: 'asha'),
    stories: [story('a'), story('b')],
  );

  Widget host({
    StoryProvider? stories,
    String signedInAs = 'someone-else',
    StoryGroupModel? viewing,
  }) => MultiProvider(
    providers: [
      ChangeNotifierProvider<StoryProvider>(
        create: (_) => stories ?? _OfflineStoryProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _FakeAuthProvider(signedInAs),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StoryViewerScreen(group: viewing ?? defaultGroup),
    ),
  );

  /// Progress of the first story's segment: 1.0 once the viewer has moved on.
  double firstSegment(WidgetTester tester) =>
      tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .first
          .value ??
      0;

  testWidgets('an image story runs its full 5s with animations disabled', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    await tester.pumpWidget(host());

    // Well past the 250ms the story used to get (5s scaled to 5%).
    await tester.pump(const Duration(seconds: 1));
    expect(
      firstSegment(tester),
      lessThan(1.0),
      reason: 'the first story should still be on screen after 1s',
    );

    await tester.pump(const Duration(seconds: 4, milliseconds: 100));
    expect(
      firstSegment(tester),
      1.0,
      reason: 'the first story should have handed off by 5s',
    );
  });

  testWidgets('pacing is unchanged when animations are enabled', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    await tester.pump(const Duration(seconds: 1));
    expect(firstSegment(tester), lessThan(1.0));

    await tester.pump(const Duration(seconds: 4, milliseconds: 100));
    expect(firstSegment(tester), 1.0);
  });

  group('deleting a status', () {
    // The author of the fixture stories is 'u1'.
    const author = 'u1';

    // The story timer schedules frames for as long as a status is on screen,
    // so pumpAndSettle would never return — advance explicitly instead.
    Future<void> advance(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('is offered on your own status', (tester) async {
      await tester.pumpWidget(host(signedInAs: author));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets("is not offered on someone else's", (tester) async {
      await tester.pumpWidget(host(signedInAs: 'someone-else'));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      // Sharing is still there, so this isn't just an empty header.
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('asks first, and does nothing if you say no', (tester) async {
      final provider = _OfflineStoryProvider();
      await tester.pumpWidget(host(stories: provider, signedInAs: author));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await advance(tester);
      expect(find.text('Delete status'), findsWidgets);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await advance(tester);

      expect(provider.deleted, isEmpty);
      expect(find.byType(StoryViewerScreen), findsOneWidget);
    });

    testWidgets('confirming deletes it and moves to the next', (tester) async {
      final provider = _OfflineStoryProvider();
      await tester.pumpWidget(host(stories: provider, signedInAs: author));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await advance(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete status'));
      await advance(tester);

      expect(provider.deleted, ['a']);
      // One story gone, so one segment left — and still on screen.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('deleting the only status closes the viewer', (tester) async {
      final provider = _OfflineStoryProvider();
      final single = StoryGroupModel(
        user: UserModel(id: author, name: 'asha'),
        stories: [story('a')],
      );
      // Pushed rather than `home:`, so there is something to pop back to —
      // the way the chat list opens it.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<StoryProvider>(create: (_) => provider),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => _FakeAuthProvider(author),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(group: single),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await advance(tester);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await advance(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete status'));
      await advance(tester);
      // Again, for the route's exit transition.
      await advance(tester);

      expect(provider.deleted, ['a']);
      expect(find.byType(StoryViewerScreen), findsNothing);
    });

    testWidgets('a failed delete keeps the status on screen', (tester) async {
      final provider = _OfflineStoryProvider(deleteSucceeds: false);
      await tester.pumpWidget(host(stories: provider, signedInAs: author));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await advance(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete status'));
      await advance(tester);

      expect(find.text('Could not delete this status'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });
  });

  testWidgets('the author photo is shown when they have one', (tester) async {
    final withPhoto = StoryGroupModel(
      user: UserModel(
        id: 'u1',
        name: 'asha',
        avatarUrl: 'https://cdn.example/asha.jpg',
      ),
      stories: [story('a')],
    );
    await tester.pumpWidget(host(viewing: withPhoto));
    await tester.pump();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar.backgroundImage, isNotNull);
    // The initial is a fallback, not what a user with a photo should see.
    expect(find.text('A'), findsNothing);
  });

  testWidgets('the initial stands in when they have no photo', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar.backgroundImage, isNull);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('a long name and every action fit the header', (tester) async {
    // 1080x2400 at 3x is a 360dp-wide phone — where this overflowed by 8px
    // once the delete button joined share and close.
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final longName = StoryGroupModel(
      user: UserModel(id: 'u1', name: 'Nitish Vishwakarma'),
      stories: [story('a')],
    );
    // Signed in as the author, so the delete button is there too.
    await tester.pumpWidget(host(signedInAs: 'u1', viewing: longName));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
