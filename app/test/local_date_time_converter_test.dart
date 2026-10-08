import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/models/converters/local_date_time_converter.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/models/user_model.dart';

void main() {
  group('LocalDateTimeConverter', () {
    const converter = LocalDateTimeConverter();

    test('a UTC timestamp from the server is parsed as local time', () {
      // Node's Date -> JSON is always a Z-suffixed UTC string, whatever the
      // server's own TZ is set to — this is exactly what the API sends.
      final parsed = converter.fromJson('2026-07-31T10:00:00.000Z');
      expect(parsed.isUtc, isFalse);
      // The same instant, just no longer read back as UTC clock digits.
      expect(parsed.toUtc(), DateTime.utc(2026, 7, 31, 10, 0, 0));
    });

    test('round-trips through toJson back to the same UTC instant', () {
      final local = converter.fromJson('2026-07-31T10:00:00.000Z');
      expect(converter.toJson(local), '2026-07-31T10:00:00.000Z');
    });

    test('a string with no offset is treated as already local, unchanged', () {
      // What ChatMessageModel.fromJson's own DateTime.now().toIso8601String()
      // fallback produces for an optimistic, not-yet-server-confirmed message.
      final withoutZ = DateTime(2026, 7, 31, 15, 30);
      final parsed = converter.fromJson(withoutZ.toIso8601String());
      expect(parsed, withoutZ);
    });
  });

  group('LocalDateTimeConverterNullable', () {
    const converter = LocalDateTimeConverterNullable();

    test('passes null straight through both directions', () {
      expect(converter.fromJson(null), isNull);
      expect(converter.toJson(null), isNull);
    });

    test('treats an empty string the same as absent', () {
      expect(converter.fromJson(''), isNull);
    });

    test('converts a present value the same way as the non-nullable form', () {
      final parsed = converter.fromJson('2026-01-01T00:00:00.000Z');
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isFalse);
      expect(parsed.toUtc(), DateTime.utc(2026, 1, 1));
    });
  });

  group('wired into the models the chat screens actually read from', () {
    test('ChatMessageModel.createdAt is local straight out of fromJson', () {
      final message = ChatMessageModel.fromJson({
        '_id': 'm1',
        'chatId': 'c1',
        'senderId': 'u1',
        'senderName': 'Sender',
        'messageType': 'text',
        'content': 'hi',
        // Deliberately a UTC instant that lands on a different calendar day
        // once shifted into a positive-offset local zone — this is the
        // symptom in the bug report: a message reads as "yesterday" or shows
        // the wrong hour because .hour/.day were read off the raw UTC value.
        'createdAt': '2026-07-31T23:30:00.000Z',
        'updatedAt': '2026-07-31T23:30:00.000Z',
      });
      expect(message.createdAt.isUtc, isFalse);
      expect(message.createdAt.toUtc(), DateTime.utc(2026, 7, 31, 23, 30));
    });

    test('a null editedAt/pinnedAt/deletedAt stays null after fromJson', () {
      final message = ChatMessageModel.fromJson({
        '_id': 'm1',
        'chatId': 'c1',
        'senderId': 'u1',
        'senderName': 'Sender',
        'messageType': 'text',
        'content': 'hi',
        'createdAt': '2026-07-31T10:00:00.000Z',
        'updatedAt': '2026-07-31T10:00:00.000Z',
      });
      expect(message.editedAt, isNull);
      expect(message.pinnedAt, isNull);
      expect(message.deletedAt, isNull);
    });

    test('UserModel.lastSeenAt is local, not the raw UTC instant', () {
      final user = UserModel.fromJson({
        '_id': 'u1',
        'name': 'Someone',
        'lastSeenAt': '2026-07-31T23:30:00.000Z',
      });
      expect(user.lastSeenAt, isNotNull);
      expect(user.lastSeenAt!.isUtc, isFalse);
      expect(user.lastSeenAt!.toUtc(), DateTime.utc(2026, 7, 31, 23, 30));
    });
  });
}
