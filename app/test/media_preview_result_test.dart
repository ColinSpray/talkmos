import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/screens/media_preview_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// The contract the chat's send flows depend on: what MediaPreviewScreen pops.
void main() {
  // 1x1 transparent PNG.
  final pngBytes = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
      'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    ),
  );

  Future<Map<String, dynamic>?> openPreview(WidgetTester tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MediaPreviewScreen(
                        fileBytes: pngBytes,
                        fileName: 'holiday.png',
                        mimeType: 'image/png',
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('the preview opens for a picked image', (tester) async {
    await openPreview(tester);

    expect(find.byType(MediaPreviewScreen), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('sending returns the caption and the file', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MediaPreviewScreen(
                        fileBytes: pngBytes,
                        fileName: 'holiday.png',
                        mimeType: 'image/png',
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, ' at the beach ');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!['confirmed'], isTrue);
    expect(result!['caption'], 'at the beach');
    expect(result!['fileName'], 'holiday.png');
    expect(result!['mimeType'], 'image/png');
    expect(result!['fileBytes'], pngBytes);
  });

  group('previewKindFor', () {
    test('routes each family to its own preview', () {
      expect(previewKindFor('image/png'), PreviewKind.image);
      expect(previewKindFor('image/jpeg'), PreviewKind.image);
      expect(previewKindFor('video/mp4'), PreviewKind.video);
      expect(previewKindFor('audio/mpeg'), PreviewKind.audio);
      expect(previewKindFor('application/pdf'), PreviewKind.file);
      expect(previewKindFor('text/csv'), PreviewKind.file);
    });

    test('is case-insensitive', () {
      expect(previewKindFor('IMAGE/PNG'), PreviewKind.image);
      expect(previewKindFor('Video/MP4'), PreviewKind.video);
    });

    test('an unknown type still gets a preview rather than none', () {
      expect(previewKindFor('application/x-whatever'), PreviewKind.file);
      expect(previewKindFor(''), PreviewKind.file);
    });
  });

  testWidgets('a document gets a preview with its name and size', (
    tester,
  ) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MediaPreviewScreen(
                        fileBytes: Uint8List(2048),
                        fileName: 'invoice.pdf',
                        mimeType: 'application/pdf',
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('invoice.pdf'), findsOneWidget);
    // Type and size on one line, the way the sent bubble shows the same file.
    // No page count here: these bytes are not a real PDF, so the render fails
    // and the card falls back to the icon rather than spinning forever.
    expect(find.text('PDF · 2.0 KB'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    // Editing tools belong to images only.
    expect(find.byIcon(Icons.crop_rounded), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'last month');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(result!['confirmed'], isTrue);
    expect(result!['caption'], 'last month');
  });

  testWidgets('image editing tools are offered for images', (tester) async {
    await openPreview(tester);

    expect(find.byIcon(Icons.crop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
  });

  testWidgets('backing out returns nothing to send', (tester) async {
    await openPreview(tester);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(MediaPreviewScreen), findsNothing);
  });
}
