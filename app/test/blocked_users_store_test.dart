import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkmos/features/users/services/blocked_users_store.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/models/recent_chat.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BlockedUsersStore.clear();
  });

  group('BlockedUsersStore', () {
    test(
      'sync makes the id visible to the synchronous socket-path check',
      () async {
        expect(BlockedUsersStore.isBlocked('u1'), isFalse);
        await BlockedUsersStore.sync(['u1', 'u2']);
        expect(BlockedUsersStore.isBlocked('u1'), isTrue);
        expect(BlockedUsersStore.isBlocked('u2'), isTrue);
        expect(BlockedUsersStore.isBlocked('u3'), isFalse);
      },
    );

    test('sync reaches disk, which is all the FCM isolate can read', () async {
      await BlockedUsersStore.sync(['u1']);
      expect(await BlockedUsersStore.isBlockedOnDisk('u1'), isTrue);
      expect(await BlockedUsersStore.isBlockedOnDisk('u2'), isFalse);
    });

    test(
      'warmUp restores the memory cache from disk on a cold start',
      () async {
        SharedPreferences.setMockInitialValues({
          'blocked_user_ids': ['u1'],
        });
        // Nothing synced this run — exactly the state a fresh launch starts in.
        expect(BlockedUsersStore.isBlocked('u1'), isFalse);
        await BlockedUsersStore.warmUp();
        expect(BlockedUsersStore.isBlocked('u1'), isTrue);
      },
    );

    test(
      'sync replaces rather than merges, so unblocking takes effect',
      () async {
        await BlockedUsersStore.sync(['u1', 'u2']);
        await BlockedUsersStore.sync(['u1']);
        expect(BlockedUsersStore.isBlocked('u2'), isFalse);
        expect(await BlockedUsersStore.isBlockedOnDisk('u2'), isFalse);
      },
    );

    test('clear empties both copies — the mirror is per-account', () async {
      await BlockedUsersStore.sync(['u1']);
      await BlockedUsersStore.clear();
      expect(BlockedUsersStore.isBlocked('u1'), isFalse);
      expect(await BlockedUsersStore.isBlockedOnDisk('u1'), isFalse);
    });

    test('an empty id is never blocked', () async {
      await BlockedUsersStore.sync(['']);
      expect(BlockedUsersStore.isBlocked(''), isFalse);
      expect(await BlockedUsersStore.isBlockedOnDisk(''), isFalse);
    });
  });

  group('RecentChat.peerFor', () {
    RecentChat chatWith(List<ChatMember> members, {String type = 'direct'}) =>
        RecentChat(
          id: 'c1',
          chatType: type,
          createdAt: DateTime(2026),
          name: 'Chat',
          imageUrl: '',
          members: members,
          isPinned: false,
          isMuted: false,
          isArchived: false,
          unreadCount: 0,
        );

    test('returns the member who is not me', () {
      final chat = chatWith([
        ChatMember(id: 'me', name: 'Me'),
        ChatMember(id: 'them', name: 'Them'),
      ]);
      expect(chat.peerFor('me')?.id, 'them');
      expect(chat.peerFor('them')?.id, 'me');
    });

    test('is null for groups — there is no single peer to block', () {
      final chat = chatWith([
        ChatMember(id: 'me', name: 'Me'),
        ChatMember(id: 'them', name: 'Them'),
      ], type: 'group');
      expect(chat.peerFor('me'), isNull);
    });

    test('is null when the server sent no member details', () {
      expect(chatWith(const []).peerFor('me'), isNull);
    });

    test('does not fall back to lastMessageSenderId when I sent last', () {
      // The bug this getter replaces: keying off the last sender resolves to
      // this account's own id whenever the last word was ours.
      final chat = RecentChat(
        id: 'c1',
        chatType: 'direct',
        createdAt: DateTime(2026),
        name: 'Chat',
        imageUrl: '',
        members: [
          ChatMember(id: 'me', name: 'Me'),
          ChatMember(id: 'them', name: 'Them'),
        ],
        lastMessage: ChatMessageModel(
          id: 'm1',
          chatId: 'c1',
          senderId: 'me',
          senderName: 'Me',
          messageType: MessageType.text,
          content: 'hi',
          media: const MessageMedia(),
          mentions: const [],
          forwarded: false,
          edited: false,
          status: MessageStatus.sent,
          isPinned: false,
          deletedForEveryone: false,
          deletedForMe: const [],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        isPinned: false,
        isMuted: false,
        isArchived: false,
        unreadCount: 0,
      );
      expect(chat.lastMessageSenderId, 'me');
      expect(chat.peerFor('me')?.id, 'them');
    });
  });
}
