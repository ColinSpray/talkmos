import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkmos/core/services/app_permissions.dart';
import 'package:talkmos/features/system/services/splash_gate.dart';
import 'package:talkmos/features/system/services/startup_permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SplashGate.reset();
    StartupPermissions.resetForTest();
  });

  tearDown(SplashGate.reset);

  group('what is asked for', () {
    test('covers the permissions the app actually uses', () {
      expect(
        StartupPermissions.startupPermissions,
        containsAll([
          AppPermission.camera,
          AppPermission.microphone,
          AppPermission.contacts,
          AppPermission.location,
        ]),
      );
    });

    test('leaves out what the app neither declares nor needs', () {
      // Bluetooth is unused, and the system photo picker needs no media
      // permission — asking for either shows a dialog the OS refuses outright,
      // since neither is in the manifest.
      expect(
        StartupPermissions.startupPermissions,
        isNot(contains(AppPermission.bluetooth)),
      );
      expect(
        StartupPermissions.startupPermissions,
        isNot(contains(AppPermission.gallery)),
      );
    });

    test('does not ask for background location among the rest', () {
      // "Always" is a heavier consent, asked once and only of Nearby users.
      expect(
        StartupPermissions.startupPermissions,
        isNot(contains(AppPermission.locationAlways)),
      );
    });
  });

  group('when it asks', () {
    /// A context to ask from, plus a poll that runs in the same zone the
    /// permission work does — starting it under fake time and driving it with
    /// runAsync would leave it stranded between the two.
    Future<BuildContext> hostContext(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      return tester.element(find.byType(SizedBox));
    }

    Future<bool> waitFor(bool Function() done, {int ticks = 40}) async {
      for (var i = 0; i < ticks && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      return done();
    }

    testWidgets('nothing happens while the splash is still up', (tester) async {
      final context = await hostContext(tester);

      await tester.runAsync(() async {
        var finished = false;
        unawaited(
          StartupPermissions.ensure(context).then((_) => finished = true),
        );

        expect(
          await waitFor(() => finished, ticks: 8),
          isFalse,
          reason: 'it should still be waiting on the splash',
        );
      });
    });

    testWidgets('it runs once the splash hands over', (tester) async {
      final context = await hostContext(tester);

      await tester.runAsync(() async {
        var finished = false;
        unawaited(
          StartupPermissions.ensure(context).then((_) => finished = true),
        );
        expect(await waitFor(() => finished, ticks: 4), isFalse);

        SplashGate.markFinished();

        expect(await waitFor(() => finished), isTrue);
      });
    });

    testWidgets('a second call in the same launch does not ask again', (
      tester,
    ) async {
      final context = await hostContext(tester);
      SplashGate.markFinished();

      await tester.runAsync(() async {
        var first = false;
        unawaited(StartupPermissions.ensure(context).then((_) => first = true));
        expect(await waitFor(() => first), isTrue);

        // The guard is what stops the prompts reappearing every time the user
        // tabs back to Home.
        var second = false;
        unawaited(
          StartupPermissions.ensure(context).then((_) => second = true),
        );

        expect(
          await waitFor(() => second, ticks: 2),
          isTrue,
          reason: 'it should return immediately',
        );
      });
    });
  });

  group('when to send someone to Settings about notifications', () {
    test('never after a grant', () async {
      expect(
        await StartupPermissions.shouldOfferSettings(PermissionOutcome.granted),
        isFalse,
      );
    });

    test('not after a plain refusal — the OS will ask again', () async {
      // Nagging someone who just said no is how an app teaches people to
      // dismiss its sheets on sight.
      expect(
        await StartupPermissions.shouldOfferSettings(PermissionOutcome.denied),
        isFalse,
      );
    });

    test('yes once the dialog will no longer appear', () async {
      expect(
        await StartupPermissions.shouldOfferSettings(
          PermissionOutcome.permanentlyDenied,
        ),
        isTrue,
      );
    });

    test(
      'an unreadable state is not a reason to send anyone anywhere',
      () async {
        // Android below 13 has no runtime permission, so this falls through to
        // the notification switch — unavailable here, and unknown must not turn
        // into a sheet.
        expect(
          await StartupPermissions.shouldOfferSettings(
            PermissionOutcome.notApplicable,
          ),
          isFalse,
        );
      },
    );
  });
}
