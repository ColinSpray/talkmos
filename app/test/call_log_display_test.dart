import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/calls/utils/call_log_display.dart';
import 'package:talkmos/models/call_model.dart';
import 'package:talkmos/models/call_participant_model.dart';
import 'package:talkmos/models/user_model.dart';

const me = 'me-id';
const unknown = 'Unknown';

UserModel _user(String id, String name) => UserModel(id: id, name: name);

CallParticipantModel _p(String id, String? name) => CallParticipantModel(
  id: 'p-$id',
  callId: 'c1',
  userId: id,
  userDetails: name == null ? null : _user(id, name),
  role: 'participant',
);

CallModel _call({
  required String scope,
  required String initiatorId,
  UserModel? initiatorDetails,
  required List<CallParticipantModel> participants,
  String? conversationId = 'conv-1',
}) => CallModel(
  id: 'c1',
  conversationId: conversationId,
  type: 'voice',
  scope: scope,
  initiatorId: initiatorId,
  initiatorDetails: initiatorDetails,
  status: 'ended',
  startedAt: DateTime(2026, 1, 1),
  participants: participants,
);

void main() {
  group('group calls show the group name', () {
    test('uses the conversation title, not a single participant', () {
      final log = _call(
        scope: 'group',
        initiatorId: 'alice',
        initiatorDetails: _user('alice', 'Alice'),
        participants: [_p(me, 'Me'), _p('alice', 'Alice'), _p('bob', 'Bob')],
      );

      expect(
        callLogTitle(
          log: log,
          currentUserId: me,
          conversationTitle: 'Design Team',
          unknownLabel: unknown,
        ),
        'Design Team',
      );
    });

    test('falls back to naming participants when the group is unresolved', () {
      final log = _call(
        scope: 'group',
        initiatorId: 'alice',
        participants: [_p(me, 'Me'), _p('alice', 'Alice'), _p('bob', 'Bob')],
      );

      // Not just the caller — everyone else who was on it.
      expect(
        callLogTitle(
          log: log,
          currentUserId: me,
          conversationTitle: null,
          unknownLabel: unknown,
        ),
        'Alice, Bob',
      );
    });

    test('summarises large calls as "A, B +n"', () {
      final log = _call(
        scope: 'group',
        initiatorId: 'alice',
        participants: [
          _p(me, 'Me'),
          _p('alice', 'Alice'),
          _p('bob', 'Bob'),
          _p('carol', 'Carol'),
          _p('dave', 'Dave'),
        ],
      );

      expect(
        callLogTitle(
          log: log,
          currentUserId: me,
          conversationTitle: null,
          unknownLabel: unknown,
        ),
        'Alice, Bob +2',
      );
    });
  });

  group('a 1:1 upgraded into a conference', () {
    // inviteToCall grows a direct call into a conference but the server keeps
    // scope '1:1', which is why these used to render as a two-person call
    // titled with one name.
    final upgraded = _call(
      scope: '1:1',
      initiatorId: 'alice',
      initiatorDetails: _user('alice', 'Alice'),
      participants: [_p(me, 'Me'), _p('alice', 'Alice'), _p('bob', 'Bob')],
    );

    test('is detected as multi-party despite scope 1:1', () {
      expect(isGroupCall(upgraded), isTrue);
    });

    test('names everyone present, not just the caller', () {
      expect(
        callLogTitle(
          log: upgraded,
          currentUserId: me,
          conversationTitle: null,
          unknownLabel: unknown,
        ),
        'Alice, Bob',
      );
    });
  });

  group('1:1 calls name the other person in both directions', () {
    test('incoming', () {
      final log = _call(
        scope: '1:1',
        initiatorId: 'alice',
        initiatorDetails: _user('alice', 'Alice'),
        participants: [_p(me, 'Me'), _p('alice', 'Alice')],
      );
      expect(
        callLogTitle(
          log: log,
          currentUserId: me,
          conversationTitle: null,
          unknownLabel: unknown,
        ),
        'Alice',
      );
      expect(isGroupCall(log), isFalse);
    });

    test('outgoing', () {
      final log = _call(
        scope: '1:1',
        initiatorId: me,
        initiatorDetails: _user(me, 'Me'),
        participants: [_p(me, 'Me'), _p('alice', 'Alice')],
      );
      expect(
        callLogTitle(
          log: log,
          currentUserId: me,
          conversationTitle: null,
          unknownLabel: unknown,
        ),
        'Alice',
      );
    });

    test('outgoing with no other participant never shows my own name', () {
      final log = _call(
        scope: '1:1',
        initiatorId: me,
        initiatorDetails: _user(me, 'Me'),
        participants: [_p(me, 'Me')],
      );
      expect(
        callLogTitle(
          log: log,
          currentUserId: me,
          conversationTitle: null,
          unknownLabel: unknown,
        ),
        unknown,
      );
    });
  });

  group('avatars follow the same rules', () {
    test('group uses the conversation avatar', () {
      final log = _call(
        scope: 'group',
        initiatorId: 'alice',
        participants: [_p(me, 'Me'), _p('alice', 'Alice'), _p('bob', 'Bob')],
      );
      expect(
        callLogAvatarUrl(
          log: log,
          currentUserId: me,
          conversationAvatarUrl: 'https://x/group.png',
        ),
        'https://x/group.png',
      );
    });

    test('outgoing 1:1 never falls back to my own avatar', () {
      final log = _call(
        scope: '1:1',
        initiatorId: me,
        initiatorDetails: UserModel(
          id: me,
          name: 'Me',
          avatarUrl: 'https://x/mine.png',
        ),
        participants: [_p(me, 'Me')],
      );
      expect(
        callLogAvatarUrl(
          log: log,
          currentUserId: me,
          conversationAvatarUrl: null,
        ),
        isNull,
      );
    });
  });
}
