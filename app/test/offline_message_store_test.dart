import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talkmos/core/database/database_helper.dart';
import 'package:talkmos/core/database/offline_message_store.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/models/recent_chat.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await dotenv.load(fileName: '.env');
  });

  setUp(() async {
    await DatabaseHelper.instance.wipeAll();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  ChatMessageModel makeMessage({
    required String id,
    required String chatId,
    required String senderId,
    String content = 'hello',
    MessageStatus status = MessageStatus.sent,
    bool deletedForEveryone = false,
  }) {
    final now = DateTime.now();
    return ChatMessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: 'Sender',
      messageType: MessageType.text,
      content: content,
      media: const MessageMedia(),
      mentions: const [],
      forwarded: false,
      edited: false,
      status: status,
      isPinned: false,
      deletedForEveryone: deletedForEveryone,
      deletedForMe: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  test('message content round-trips through encryption', () async {
    final store = OfflineMessageStore.instance;
    final msg = makeMessage(
      id: 'm1',
      chatId: 'c1',
      senderId: 'u1',
      content: 'secret text',
    );
    await store.upsert(msg, 'u1');

    final fetched = await store.getMessages('c1', 'u1');
    expect(fetched.length, 1);
    expect(fetched.first.content, 'secret text');
    expect(fetched.first.id, 'm1');
  });

  test(
    'deleted-for-everyone messages store empty content, not the plaintext',
    () async {
      final store = OfflineMessageStore.instance;
      final msg = makeMessage(
        id: 'm2',
        chatId: 'c1',
        senderId: 'u1',
        content: 'should not persist',
        deletedForEveryone: true,
      );
      await store.upsert(msg, 'u1');

      final fetched = await store.getMessages('c1', 'u1');
      final found = fetched.firstWhere((m) => m.id == 'm2');
      expect(found.content, '');
      expect(found.deletedForEveryone, true);
    },
  );

  test('updateStatus only touches the target message', () async {
    final store = OfflineMessageStore.instance;
    await store.upsert(
      makeMessage(id: 'm3', chatId: 'c2', senderId: 'u1'),
      'u1',
    );
    await store.upsert(
      makeMessage(id: 'm4', chatId: 'c2', senderId: 'u1'),
      'u1',
    );
    await store.updateStatus('m3', MessageStatus.read);

    final fetched = await store.getMessages('c2', 'u1');
    expect(fetched.firstWhere((m) => m.id == 'm3').status, MessageStatus.read);
    expect(fetched.firstWhere((m) => m.id == 'm4').status, MessageStatus.sent);
  });

  test(
    'delete removes a message; deleteMessagesForChat clears a whole chat',
    () async {
      final store = OfflineMessageStore.instance;
      await store.upsert(
        makeMessage(id: 'm5', chatId: 'c3', senderId: 'u1'),
        'u1',
      );
      await store.upsert(
        makeMessage(id: 'm6', chatId: 'c3', senderId: 'u1'),
        'u1',
      );

      await store.delete('m5');
      var fetched = await store.getMessages('c3', 'u1');
      expect(fetched.map((m) => m.id), ['m6']);

      await store.deleteMessagesForChat('c3');
      fetched = await store.getMessages('c3', 'u1');
      expect(fetched, isEmpty);
    },
  );

  test(
    'recent chats round-trip through JSON, including nested lastMessage',
    () async {
      final store = OfflineMessageStore.instance;
      final now = DateTime.now();
      final chat = RecentChat(
        id: 'chat1',
        chatType: 'direct',
        createdAt: now,
        name: 'Alice',
        imageUrl: '',
        isPinned: true,
        isMuted: false,
        isArchived: false,
        unreadCount: 3,
        lastMessage: makeMessage(
          id: 'lm1',
          chatId: 'chat1',
          senderId: 'u2',
          content: 'hey there',
        ),
      );
      await store.saveChats([chat], archived: false);

      final cached = await store.getCachedChats(archived: false);
      expect(cached.length, 1);
      expect(cached.first.id, 'chat1');
      expect(cached.first.isPinned, true);
      expect(cached.first.unreadCount, 3);
      expect(cached.first.lastMessageContent, 'hey there');

      // Archived query must not return it.
      final archived = await store.getCachedChats(archived: true);
      expect(archived, isEmpty);
    },
  );

  test('removeCachedChat removes only that chat', () async {
    final store = OfflineMessageStore.instance;
    final now = DateTime.now();
    RecentChat mk(String id) => RecentChat(
      id: id,
      chatType: 'direct',
      createdAt: now,
      name: id,
      imageUrl: '',
      isPinned: false,
      isMuted: false,
      isArchived: false,
      unreadCount: 0,
    );
    await store.saveChats([mk('a'), mk('b')], archived: false);
    await store.removeCachedChat('a');

    final cached = await store.getCachedChats(archived: false);
    expect(cached.map((c) => c.id), ['b']);
  });

  test('wipeAll clears messages and chats', () async {
    final store = OfflineMessageStore.instance;
    await store.upsert(
      makeMessage(id: 'm7', chatId: 'c4', senderId: 'u1'),
      'u1',
    );
    await store.saveChats([
      RecentChat(
        id: 'chatX',
        chatType: 'direct',
        createdAt: DateTime.now(),
        name: 'X',
        imageUrl: '',
        isPinned: false,
        isMuted: false,
        isArchived: false,
        unreadCount: 0,
      ),
    ], archived: false);

    await DatabaseHelper.instance.wipeAll();

    expect(await store.getMessages('c4', 'u1'), isEmpty);
    expect(await store.getCachedChats(archived: false), isEmpty);
  });

  test('saveAll/getMessages round-trip a batch above the isolate threshold '
      'correctly, each message keeping its own distinct content', () async {
    final store = OfflineMessageStore.instance;
    // 12 > cryptoIsolateThreshold (8) — exercises the background-isolate
    // batch path in both _toRowsBatch (write) and _decryptRowsBatch (read),
    // not just the inline fallback for small batches.
    final messages = [
      for (var i = 0; i < 12; i++)
        makeMessage(
          id: 'batch_m$i',
          chatId: 'batchChat',
          senderId: 'user$i',
          content: 'message number $i',
        ),
    ];

    await store.saveAll(messages, 'viewer1');
    final fetched = await store.getMessages('batchChat', 'viewer1', limit: 20);

    expect(fetched.length, 12);
    for (var i = 0; i < 12; i++) {
      final match = fetched.firstWhere((m) => m.id == 'batch_m$i');
      expect(match.content, 'message number $i');
    }
  });
}
