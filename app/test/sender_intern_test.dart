import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/models/chat_message_model.dart';

Map<String, dynamic> raw(String id, String senderId) => {
  '_id': id,
  'chatId': 'c1',
  // The API embeds the whole user object on every message. Each of these is a
  // distinct String instance, exactly as jsonDecode would produce.
  'senderId': {
    '_id': senderId,
    'name': String.fromCharCodes('nitish vishwakarma'.codeUnits),
    'avatarUrl': String.fromCharCodes(
      'https://lh3.googleusercontent.com/a/ACg8ocLqn-lbIou5yBVLy4ZSbTN5=s96-c'
          .codeUnits,
    ),
  },
  'messageType': 'text',
  'content': 'hi',
  'createdAt': '2026-07-28T14:47:02.645Z',
  'updatedAt': '2026-07-28T14:47:02.645Z',
};

void main() {
  setUp(ChatMessageModel.clearSenderCache);

  test('messages from one sender share the same name and avatar instances', () {
    final a = ChatMessageModel.fromJson(raw('m1', 'u1'));
    final b = ChatMessageModel.fromJson(raw('m2', 'u1'));

    expect(a.senderName, b.senderName);
    expect(
      identical(a.senderName, b.senderName),
      isTrue,
      reason: 'equal strings must be one instance, not a copy per message',
    );
    expect(identical(a.senderAvatarUrl, b.senderAvatarUrl), isTrue);
    expect(identical(a.senderId, b.senderId), isTrue);
  });

  test('distinct senders keep distinct values', () {
    final a = ChatMessageModel.fromJson(raw('m1', 'u1'));
    final c = ChatMessageModel.fromJson({
      ...raw('m3', 'u2'),
      'senderId': {'_id': 'u2', 'name': 'someone else', 'avatarUrl': ''},
    });
    expect(a.senderId, isNot(c.senderId));
    expect(a.senderName, isNot(c.senderName));
    expect(c.senderAvatarUrl, isEmpty);
  });
}
