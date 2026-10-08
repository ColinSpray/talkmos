import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/widgets/quoted_message_preview.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/chat_message_model.dart';

ChatMessageModel _message(
  MessageType type, {
  String content = '',
  MessageMedia media = const MessageMedia(),
}) {
  final now = DateTime(2026, 9, 15);
  return ChatMessageModel(
    id: 'm1',
    chatId: 'c1',
    senderId: 'u1',
    senderName: 'Sender',
    messageType: type,
    content: content,
    media: media,
    mentions: const [],
    forwarded: false,
    edited: false,
    status: MessageStatus.sent,
    isPinned: false,
    deletedForEveryone: false,
    deletedForMe: const [],
    createdAt: now,
    updatedAt: now,
  );
}

Future<({IconData? icon, String label})> _previewOf(
  WidgetTester tester,
  ChatMessageModel message,
) async {
  late ({IconData? icon, String label}) result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          result = quotedPreviewOf(context, message);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

void main() {
  testWidgets('a quoted photo says so instead of showing nothing', (
    tester,
  ) async {
    final preview = await _previewOf(tester, _message(MessageType.image));
    expect(preview.label, 'Photo');
    expect(preview.icon, isNotNull);
  });

  testWidgets('a quoted voice message too', (tester) async {
    final preview = await _previewOf(tester, _message(MessageType.voice));
    expect(preview.label, 'Voice message');
  });

  testWidgets('a document is named when it has one', (tester) async {
    final preview = await _previewOf(
      tester,
      _message(
        MessageType.file,
        media: const MessageMedia(fileName: 'invoice.pdf'),
      ),
    );
    expect(preview.label, 'invoice.pdf');
  });

  testWidgets('text quotes itself, with no icon', (tester) async {
    final preview = await _previewOf(
      tester,
      _message(MessageType.text, content: 'see you at six'),
    );
    expect(preview.label, 'see you at six');
    expect(preview.icon, isNull);
  });

  test('only photos carry a thumbnail into the quote', () {
    expect(
      quotedThumbnailOf(
        _message(
          MessageType.image,
          media: const MessageMedia(url: 'https://example.test/p.jpg'),
        ),
      ),
      'https://example.test/p.jpg',
    );
    // A video's own URL is not an image — only its thumbnail will do.
    expect(
      quotedThumbnailOf(
        _message(
          MessageType.video,
          media: const MessageMedia(url: 'https://example.test/v.mp4'),
        ),
      ),
      isNull,
    );
    expect(quotedThumbnailOf(_message(MessageType.text)), isNull);
  });
}
