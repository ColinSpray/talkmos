import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/features/chats/widgets/message_content/contact_message_content.dart';
import 'package:talkmos/features/chats/widgets/message_content/document_message_content.dart';
import 'package:talkmos/features/chats/widgets/message_content/location_message_content.dart';

/// Stands in for the bubble's timestamp and tick.
const _metaKey = Key('meta');
const _meta = SizedBox(key: _metaKey, width: 46, height: 12);

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

ChatMessageModel _fileMessage({required String fileName, required int size}) =>
    ChatMessageModel(
      id: 'm1',
      chatId: 'c1',
      senderId: 'u1',
      senderName: 'Nitish',
      messageType: MessageType.file,
      content: '',
      media: MessageMedia(
        url: 'https://cdn.talkmos.app/files/$fileName',
        fileName: fileName,
        mimeType: 'application/pdf',
        size: size,
      ),
      mentions: const [],
      forwarded: false,
      edited: false,
      status: MessageStatus.sent,
      isPinned: false,
      deletedForEveryone: false,
      deletedForMe: const [],
      createdAt: DateTime(2026, 8, 14, 12, 36),
      updatedAt: DateTime(2026, 8, 14, 12, 36),
    );

/// Finds the muted detail line — the size, the coordinates, the number.
Finder _detailText(String contains) => find.byWidgetPredicate(
  (w) => w is Text && (w.data?.contains(contains) ?? false),
);

/// Width of the detail line's layout box.
///
/// This is exactly what the fix changed. The text used to sit in a [Flexible],
/// which shrink-wraps to the string — so the timestamp rendered 8px after the
/// last glyph and "PDF · 52 KB 12:36" read as one run-on line. In an
/// [Expanded] the box fills the line instead, carrying the timestamp to the
/// far end. A shrink-wrapped "PDF · 52.0 KB" is around 70px; a filled line is
/// well over 100.
double _detailLineWidth(WidgetTester tester, Finder detail) =>
    tester.getRect(detail).width;

/// How far the timestamp's right edge sits from the card's right edge, for
/// cards with nothing to the right of the text column.
double _gapToCardRight(WidgetTester tester, Finder card) =>
    tester.getRect(card).right - tester.getRect(find.byKey(_metaKey)).right;

void main() {
  group('the timestamp sits at the right edge of', () {
    testWidgets('a document card', (tester) async {
      await tester.pumpWidget(
        _host(
          DocumentMessageContent(
            message: _fileMessage(fileName: 'invoice.pdf', size: 52 * 1024),
            textColor: Colors.black,
            trailing: _meta,
          ),
        ),
      );
      await tester.pump();

      expect(_detailLineWidth(tester, _detailText('KB')), greaterThan(100));
      // Nothing sits right of this card's text column, so the timestamp
      // should land on the card's own padding.
      expect(
        _gapToCardRight(tester, find.byType(DocumentMessageContent)),
        lessThan(14),
      );
    });

    testWidgets('a document card with a long name that has to wrap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          DocumentMessageContent(
            message: _fileMessage(
              fileName: 'tm_file_1e055080-9a18-4c35-8454-7e9218390683.pdf',
              size: 52 * 1024,
            ),
            textColor: Colors.black,
            trailing: _meta,
          ),
        ),
      );
      await tester.pump();

      expect(_detailLineWidth(tester, _detailText('KB')), greaterThan(100));
      expect(
        _gapToCardRight(tester, find.byType(DocumentMessageContent)),
        lessThan(14),
      );
    });

    testWidgets('a location card', (tester) async {
      await tester.pumpWidget(
        _host(
          const LocationMessageContent(
            content: '{"type":"location","lat":12.9716,"lng":77.5946}',
            textColor: Colors.black,
            trailing: _meta,
          ),
        ),
      );
      await tester.pump();

      // Coordinates are longer than the line either way, so the width test
      // cannot discriminate here — pin the right edge instead. 12px of card
      // padding plus the 16px "open" icon is all that may follow it.
      expect(
        _gapToCardRight(tester, find.byType(LocationMessageContent)),
        lessThan(32),
      );
    });

    testWidgets('a contact card', (tester) async {
      await tester.pumpWidget(
        _host(
          const ContactMessageContent(
            // Short on purpose: a long number fills the line on its own, and
            // then a shrink-wrapped layout is indistinguishable from a
            // filled one.
            content: '{"type":"contact","name":"Asha","phone":"+9198"}',
            textColor: Colors.black,
            trailing: _meta,
          ),
        ),
      );
      await tester.pump();

      expect(_detailLineWidth(tester, _detailText('+9198')), greaterThan(80));
    });

    testWidgets('a contact card shared without a number', (tester) async {
      await tester.pumpWidget(
        _host(
          const ContactMessageContent(
            content: '{"type":"contact","name":"Asha","phone":""}',
            textColor: Colors.black,
            trailing: _meta,
          ),
        ),
      );
      await tester.pump();

      // Nothing to push against here, so this is the case most likely to
      // collapse back to left-aligned.
      final meta = tester.getRect(find.byKey(_metaKey));
      final card = tester.getRect(find.byType(ContactMessageContent));
      expect(meta.left, greaterThan(card.left + card.width / 2));
    });
  });
}
