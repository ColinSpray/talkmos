import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/models/friend_model.dart';
import 'package:talkmos/models/home_summary_model.dart';
import 'package:talkmos/models/shared_attachment_payloads.dart';
import 'package:talkmos/models/shared_media_item.dart';

/// Pins the decode behaviour of the models moved from hand-written fromJson
/// to json_serializable. Each case here is one the old parsers handled
/// deliberately, so a regression would be silent otherwise.
void main() {
  group('FriendModel', () {
    test('maps _id and fills defaults', () {
      final friend = FriendModel.fromJson({'_id': 'f1', 'name': 'asha'});
      expect(friend.id, 'f1');
      expect(friend.name, 'asha');
      expect(friend.isVerified, isFalse);
      expect(friend.username, isNull);
      expect(friend.chatId, isNull);
    });

    test('an empty payload does not throw', () {
      final friend = FriendModel.fromJson({});
      expect(friend.id, isEmpty);
      expect(friend.name, isEmpty);
    });

    test('carries through to UserModel', () {
      final user = FriendModel.fromJson({
        '_id': 'f2',
        'name': 'ravi',
        'isVerified': true,
      }).toUserModel();
      expect(user.id, 'f2');
      expect(user.isVerified, isTrue);
    });
  });

  group('HomeSummary', () {
    test('reads snake_case keys', () {
      final summary = HomeSummary.fromJson({
        'unread_chats': 3,
        'new_group_messages': 1,
        'missed_calls': 2,
      });
      expect(summary.unreadChats, 3);
      expect(summary.newGroupMessages, 1);
      expect(summary.missedCalls, 2);
    });

    test('missing counts read as zero', () {
      final summary = HomeSummary.fromJson({});
      expect(summary.unreadChats, 0);
      expect(summary.missedCalls, 0);
    });
  });

  group('SharedMediaItem', () {
    test('decodes a full entry', () {
      final item = SharedMediaItem.fromJson({
        '_id': 'm1',
        'messageType': 'image',
        'media': {'url': 'https://cdn.example/a.jpg'},
        'createdAt': '2026-01-02T03:04:05.000Z',
      });
      expect(item.id, 'm1');
      expect(item.messageType, MessageType.image);
      expect(item.media.url, 'https://cdn.example/a.jpg');
      // Stored local, so the gallery's day-grouping doesn't straddle midnight.
      expect(item.createdAt.isUtc, isFalse);
    });

    test('a missing media object becomes an empty one, not a throw', () {
      final item = SharedMediaItem.fromJson({
        '_id': 'm2',
        'messageType': 'video',
        'createdAt': '2026-01-02T03:04:05.000Z',
      });
      expect(item.media.url, isEmpty);
    });

    test('an unparseable createdAt costs the item its date, not the page', () {
      final item = SharedMediaItem.fromJson({
        '_id': 'm3',
        'messageType': 'image',
        'media': {'url': 'x'},
        'createdAt': 'not-a-date',
      });
      expect(item.createdAt, isA<DateTime>());
    });

    test('an unknown messageType falls back rather than throwing', () {
      final item = SharedMediaItem.fromJson({
        '_id': 'm4',
        'messageType': 'hologram',
        'media': {'url': 'x'},
        'createdAt': '2026-01-02T03:04:05.000Z',
      });
      expect(item.messageType, MessageType.text);
    });
  });

  group('SharedContactPayload', () {
    test('round-trips through encode/tryDecode', () {
      final encoded = const SharedContactPayload(
        name: 'Asha',
        phone: '+919876543210',
      ).encode();
      final decoded = SharedContactPayload.tryDecode(encoded);
      expect(decoded?.name, 'Asha');
      expect(decoded?.phone, '+919876543210');
    });

    test('coerces a numeric phone instead of throwing', () {
      // These decode a string written into a message body, possibly by an
      // older build, so a number where a string was expected must degrade.
      final decoded = SharedContactPayload.tryDecode(
        '{"name":"Asha","phone":9876543210}',
      );
      expect(decoded?.phone, '9876543210');
    });

    test('rejects a nameless payload and non-JSON content', () {
      expect(SharedContactPayload.tryDecode('{"phone":"123"}'), isNull);
      expect(SharedContactPayload.tryDecode('just some text'), isNull);
    });
  });

  group('SharedLocationPayload', () {
    test('round-trips through encode/tryDecode', () {
      final encoded = const SharedLocationPayload(
        lat: 22.5726,
        lng: 88.3639,
      ).encode();
      final decoded = SharedLocationPayload.tryDecode(encoded);
      expect(decoded?.lat, closeTo(22.5726, 1e-9));
      expect(decoded?.lng, closeTo(88.3639, 1e-9));
    });

    test('accepts integer coordinates as doubles', () {
      final decoded = SharedLocationPayload.tryDecode('{"lat":22,"lng":88}');
      expect(decoded?.lat, 22.0);
      expect(decoded?.lng, 88.0);
    });

    test('treats 0,0 and non-JSON as absent', () {
      expect(SharedLocationPayload.tryDecode('{"lat":0,"lng":0}'), isNull);
      expect(SharedLocationPayload.tryDecode('nope'), isNull);
    });
  });
}
