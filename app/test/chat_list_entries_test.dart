import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/widgets/chat_wallpaper_painter.dart';
import 'package:talkmos/models/chat_message_model.dart';

ChatMessageModel _message(String id, DateTime sentAt) => ChatMessageModel(
  id: id,
  chatId: 'chat1',
  senderId: 'userA',
  senderName: 'Sender',
  messageType: MessageType.text,
  content: id,
  media: const MessageMedia(),
  mentions: const [],
  forwarded: false,
  edited: false,
  status: MessageStatus.sent,
  isPinned: false,
  deletedForEveryone: false,
  deletedForMe: const [],
  createdAt: sentAt,
  updatedAt: sentAt,
);

void main() {
  final monday = DateTime(2026, 9, 14, 10);
  final tuesday = DateTime(2026, 9, 15, 9);

  test('newest message comes first, for the reversed list', () {
    final entries = buildChatListEntries([
      _message('m1', monday),
      _message('m2', monday.add(const Duration(minutes: 5))),
      _message('m3', tuesday),
    ]);

    expect(entries.first.message?.id, 'm3');
    expect(entries.last.date, DateTime(2026, 9, 14));
  });

  test("each day's separator sits above that day's first message", () {
    final entries = buildChatListEntries([
      _message('m1', monday),
      _message('m2', tuesday),
    ]);

    // Reversed, so "above" means a later index.
    final ids = entries.map((e) => e.message?.id ?? 'date:${e.date!.day}');
    expect(ids.toList(), ['m2', 'date:15', 'm1', 'date:14']);
  });

  test('no messages, no rows', () {
    expect(buildChatListEntries(const []), isEmpty);
  });
}
