import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/core/theme/app_theme.dart';
import 'package:talkmos/features/chats/screens/media_preview_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// The caption field and send button sit at the bottom of the media preview,
/// which is exactly where the system navigation bar is. These pin the fix so a
/// later layout change can't quietly slide them back underneath it.
void main() {
  /// A 1x1 PNG — enough for Image.memory to decode without a real fixture.
  final pngBytes = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  const navBarHeight = 48.0;
  const screenSize = Size(400, 800);

  /// The preview screen under a viewport that has a system navigation bar,
  /// the way a real Android device reports one.
  ///
  /// [dark] picks which app theme the screen is opened under — the screen is
  /// meant to follow it rather than impose its own brightness.
  Widget harness({
    double bottomInset = navBarHeight,
    Color? primary,
    bool dark = false,
  }) {
    return MediaQuery(
      data:
          const MediaQueryData(
            size: screenSize,
            padding: EdgeInsets.only(bottom: navBarHeight),
            viewPadding: EdgeInsets.only(bottom: navBarHeight),
          ).copyWith(
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
      child: MaterialApp(
        theme: dark
            ? AppTheme.getDarkTheme(primary ?? AppTheme.primary)
            : AppTheme.getLightTheme(primary ?? AppTheme.primary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaPreviewScreen(
          fileBytes: pngBytes,
          fileName: 'photo.png',
          mimeType: 'image/png',
        ),
      ),
    );
  }

  testWidgets('the send button clears the system navigation bar', (t) async {
    await t.binding.setSurfaceSize(screenSize);
    addTearDown(() => t.binding.setSurfaceSize(null));

    await t.pumpWidget(harness());
    await t.pumpAndSettle();

    final sendButton = find.byIcon(Icons.send_rounded);
    expect(sendButton, findsOneWidget);

    final bottom = t.getRect(sendButton).bottom;
    expect(
      bottom,
      lessThanOrEqualTo(screenSize.height - navBarHeight),
      reason: 'the send button is under the navigation bar',
    );
  });

  testWidgets('the caption field clears the system navigation bar', (t) async {
    await t.binding.setSurfaceSize(screenSize);
    addTearDown(() => t.binding.setSurfaceSize(null));

    await t.pumpWidget(harness());
    await t.pumpAndSettle();

    final caption = find.byType(TextField);
    expect(caption, findsOneWidget);

    expect(
      t.getRect(caption).bottom,
      lessThanOrEqualTo(screenSize.height - navBarHeight),
      reason: 'the caption field is under the navigation bar',
    );
  });

  testWidgets('no dead space is reserved on a device without a nav bar', (
    t,
  ) async {
    await t.binding.setSurfaceSize(screenSize);
    addTearDown(() => t.binding.setSurfaceSize(null));

    await t.pumpWidget(harness(bottomInset: 0));
    await t.pumpAndSettle();

    // With no inset to avoid, the bar should sit against the bottom edge
    // rather than floating above a phantom navigation bar.
    final bottom = t.getRect(find.byIcon(Icons.send_rounded)).bottom;
    expect(bottom, greaterThan(screenSize.height - navBarHeight));
  });

  testWidgets("the screen uses the app's accent, not Material's stock one", (
    t,
  ) async {
    await t.binding.setSurfaceSize(screenSize);
    addTearDown(() => t.binding.setSurfaceSize(null));

    const brandPurple = Color(0xFF7C3AED);
    await t.pumpWidget(harness(primary: brandPurple));
    await t.pumpAndSettle();

    // Read the theme the screen installs for its own subtree, rather than the
    // one handed to MaterialApp.
    final inner = Theme.of(t.element(find.byType(Scaffold).last));
    expect(inner.colorScheme.primary, brandPurple);
  });

  group('the caption field', () {
    /// The rounded container that draws the caption field's visible shape.
    BoxDecoration captionDecoration(WidgetTester t) {
      final container = t.widget<Container>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Container),
            )
            .first,
      );
      return container.decoration! as BoxDecoration;
    }

    testWidgets('has no border — the fill alone defines it', (t) async {
      await t.binding.setSurfaceSize(screenSize);
      addTearDown(() => t.binding.setSurfaceSize(null));

      await t.pumpWidget(harness());
      await t.pumpAndSettle();

      expect(captionDecoration(t).border, isNull);
    });

    testWidgets('keeps the shadow that separates it from the page', (t) async {
      await t.binding.setSurfaceSize(screenSize);
      addTearDown(() => t.binding.setSurfaceSize(null));

      await t.pumpWidget(harness(dark: false));
      await t.pumpAndSettle();

      // With no border, and cardColor == scaffold background in the light
      // theme, the shadow is the only thing distinguishing the field from the
      // page behind it. Same approach the chat composer takes.
      final shadows = captionDecoration(t).boxShadow;
      expect(shadows, isNotNull);
      expect(shadows!, isNotEmpty, reason: 'field would vanish on white');
    });

    testWidgets('matches the chat composer pill radius', (t) async {
      await t.binding.setSurfaceSize(screenSize);
      addTearDown(() => t.binding.setSurfaceSize(null));

      await t.pumpWidget(harness());
      await t.pumpAndSettle();

      expect(captionDecoration(t).borderRadius, BorderRadius.circular(25));
    });

    testWidgets('drops the attach, camera and dead placeholder buttons', (
      t,
    ) async {
      await t.binding.setSurfaceSize(screenSize);
      addTearDown(() => t.binding.setSurfaceSize(null));

      await t.pumpWidget(harness());
      await t.pumpAndSettle();

      // Kept, as on the chat composer.
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);

      // Dropped: a file is already chosen by this point.
      expect(find.byIcon(Icons.attach_file_rounded), findsNothing);
      expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);
      // Was a button wired to an empty callback.
      expect(find.byIcon(Icons.looks_one_outlined), findsNothing);
    });

    testWidgets('keeps its rounded fill in both brightnesses', (t) async {
      await t.binding.setSurfaceSize(screenSize);
      addTearDown(() => t.binding.setSurfaceSize(null));

      for (final dark in [false, true]) {
        await t.pumpWidget(harness(dark: dark));
        await t.pumpAndSettle();

        final decoration = captionDecoration(t);
        expect(decoration.borderRadius, isNotNull);
        expect(
          decoration.color,
          dark ? AppTheme.darkCard : AppTheme.lightCard,
          reason: 'fill should come from the theme, not a literal',
        );
      }
    });
  });

  group('brightness', () {
    testWidgets('a light app gives a light preview page', (t) async {
      await t.binding.setSurfaceSize(screenSize);
      addTearDown(() => t.binding.setSurfaceSize(null));

      await t.pumpWidget(harness(dark: false));
      await t.pumpAndSettle();

      final inner = Theme.of(t.element(find.byType(Scaffold).last));
      expect(
        inner.brightness,
        Brightness.light,
        reason: 'the preview must not force dark on a light app',
      );
      expect(inner.scaffoldBackgroundColor, AppTheme.lightBg);

      // Text has to invert with it, or the page is white-on-white.
      final caption = t.widget<TextField>(find.byType(TextField));
      expect(caption.style!.color, AppTheme.lightText);
    });

    testWidgets('a dark app still gives a dark preview page', (t) async {
      await t.binding.setSurfaceSize(screenSize);
      addTearDown(() => t.binding.setSurfaceSize(null));

      await t.pumpWidget(harness(dark: true));
      await t.pumpAndSettle();

      final inner = Theme.of(t.element(find.byType(Scaffold).last));
      expect(inner.brightness, Brightness.dark);
      expect(inner.scaffoldBackgroundColor, AppTheme.darkBg);

      final caption = t.widget<TextField>(find.byType(TextField));
      expect(caption.style!.color, AppTheme.darkText);
    });

    testWidgets('app bar background matches the body in light mode', (t) async {
      await t.binding.setSurfaceSize(screenSize);
      addTearDown(() => t.binding.setSurfaceSize(null));

      await t.pumpWidget(harness(dark: false));
      await t.pumpAndSettle();

      final inner = Theme.of(t.element(find.byType(Scaffold).last));
      expect(
        inner.appBarTheme.backgroundColor,
        inner.scaffoldBackgroundColor,
        reason: 'a transparent/mismatched app bar shows a seam',
      );
    });
  });

  testWidgets('the send button tints with the accent, not a fixed blue', (
    t,
  ) async {
    await t.binding.setSurfaceSize(screenSize);
    addTearDown(() => t.binding.setSurfaceSize(null));

    const brandPurple = Color(0xFF7C3AED);
    await t.pumpWidget(harness(primary: brandPurple));
    await t.pumpAndSettle();

    final circle = t.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.send_rounded),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((circle.decoration! as BoxDecoration).color, brandPurple);
  });

  testWidgets('the audio player tints with the accent, not a fixed blue', (
    t,
  ) async {
    await t.binding.setSurfaceSize(screenSize);
    addTearDown(() => t.binding.setSurfaceSize(null));

    const brandPurple = Color(0xFF7C3AED);
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: screenSize),
        child: MaterialApp(
          theme: AppTheme.getLightTheme(brandPurple),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaPreviewScreen(
            fileBytes: pngBytes,
            fileName: 'note.m4a',
            mimeType: 'audio/mp4',
          ),
        ),
      ),
    );
    await t.pump();

    // AppTheme.primaryLight was hardcoded here, so a user on any other accent
    // got Talkmos blue regardless.
    final mic = t.widget<Icon>(find.byIcon(Icons.mic_rounded));
    expect(mic.color, brandPurple);

    final play = t.widget<Icon>(find.byIcon(Icons.play_circle_filled_rounded));
    expect(play.color, brandPurple);
  });
}
