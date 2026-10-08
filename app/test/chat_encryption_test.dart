import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:talkmos/core/encryption/chat_encryption.dart';
import 'package:talkmos/models/chat_message_model.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  final encryption = ChatEncryption.instance;

  ChatMessageModel makeMessage({
    required String chatId,
    required String senderId,
    String content = 'hello there',
    bool deletedForEveryone = false,
    String id = 'm1',
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
      status: MessageStatus.sent,
      isPinned: false,
      deletedForEveryone: deletedForEveryone,
      deletedForMe: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  test('content round-trips through encrypt/decrypt', () async {
    final msg = makeMessage(
      chatId: 'chat1',
      senderId: 'userA',
      content: 'secret plans',
    );
    final encrypted = await encryption.encrypt(msg);

    expect(encrypted.content, isNot('secret plans'));
    expect(encrypted.content, contains(':')); // nonce:mac:cipherText format

    final decrypted = await encryption.decrypt(encrypted);
    expect(decrypted.content, 'secret plans');
  });

  test(
    'any participant can decrypt using only senderId + chatId (no viewer-specific key)',
    () async {
      final msg = makeMessage(
        chatId: 'group1',
        senderId: 'alice',
        content: 'team update',
      );
      final encrypted = await encryption.encrypt(msg);

      // Simulates two different group members independently decrypting the
      // exact same stored ciphertext — the key must not depend on who's
      // asking, only on the message's own senderId/chatId.
      final viewer1 = await encryption.decrypt(encrypted);
      final viewer2 = await encryption.decrypt(encrypted);
      expect(viewer1.content, 'team update');
      expect(viewer2.content, 'team update');
    },
  );

  test(
    'same content encrypted for different chats produces different ciphertext',
    () async {
      final msgA = makeMessage(
        chatId: 'chatA',
        senderId: 'userA',
        content: 'same text',
      );
      final msgB = makeMessage(
        chatId: 'chatB',
        senderId: 'userA',
        content: 'same text',
      );

      final encA = await encryption.encrypt(msgA);
      final encB = await encryption.encrypt(msgB);
      expect(encA.content, isNot(encB.content));
    },
  );

  test(
    'decrypting with the wrong chatId does not silently return the right plaintext',
    () async {
      final msg = makeMessage(
        chatId: 'realChat',
        senderId: 'userA',
        content: 'private',
      );
      final encrypted = await encryption.encrypt(msg);

      // Same ciphertext, wrong chatId -> wrong key -> decrypt must fail
      // closed (fall back to the ciphertext), never produce 'private'.
      final wrongChat = makeMessage(
        chatId: 'otherChat',
        senderId: 'userA',
        content: encrypted.content,
      );
      final result = await encryption.decrypt(wrongChat);
      expect(result.content, isNot('private'));
    },
  );

  test('empty content passes through unchanged', () async {
    final msg = makeMessage(chatId: 'c', senderId: 'u', content: '');
    final encrypted = await encryption.encrypt(msg);
    expect(encrypted.content, '');
  });

  test(
    'deletedForEveryone messages are never encrypted or decrypted',
    () async {
      final msg = makeMessage(
        chatId: 'c',
        senderId: 'u',
        content: 'This message was deleted',
        deletedForEveryone: true,
      );
      final encrypted = await encryption.encrypt(msg);
      expect(encrypted.content, 'This message was deleted');
    },
  );

  test('decrypting unencrypted legacy content falls back gracefully', () async {
    final msg = makeMessage(
      chatId: 'c',
      senderId: 'u',
      content: 'plain legacy text',
    );
    // Never encrypted (predates this feature) — decrypt must not throw.
    final result = await encryption.decrypt(msg);
    expect(result.content, 'plain legacy text');
  });

  test(
    'encryptContent/decryptContent round-trip for the edit-message path',
    () async {
      final encrypted = await encryption.encryptContent(
        'edited text',
        senderId: 'userA',
        chatId: 'chat1',
      );
      expect(encrypted, isNot('edited text'));

      final decrypted = await encryption.decryptContent(
        encrypted,
        senderId: 'userA',
        chatId: 'chat1',
      );
      expect(decrypted, 'edited text');
    },
  );

  test('decryptAll decrypts a whole page of history', () async {
    final messages = [
      makeMessage(chatId: 'c1', senderId: 'u1', content: 'one'),
      makeMessage(chatId: 'c1', senderId: 'u2', content: 'two'),
    ];
    final encrypted = await encryption.encryptAll(messages);
    final decrypted = await encryption.decryptAll(encrypted);
    expect(decrypted.map((m) => m.content), ['one', 'two']);
  });

  test('large batches (above the isolate threshold) run through compute() and '
      'each message keeps its own distinct content — not mixed up across the '
      'isolate boundary', () async {
    // 12 messages > cryptoIsolateThreshold (8), so this genuinely
    // exercises the compute()/background-isolate path, not just the
    // inline fallback. Deliberately reuses the same message id ('m1' via
    // the default) across all of them, since ChatEncryption keys batch
    // results by list position — this must still work correctly even
    // when messages don't have unique ids (e.g. locally-synthesized
    // RecentChat.lastMessage previews).
    final messages = [
      for (var i = 0; i < 12; i++)
        makeMessage(
          chatId: 'chat$i',
          senderId: 'user$i',
          content: 'message number $i',
        ),
    ];

    final encrypted = await encryption.encryptAll(messages);
    expect(encrypted.length, 12);
    for (var i = 0; i < 12; i++) {
      expect(encrypted[i].content, isNot('message number $i'));
    }

    final decrypted = await encryption.decryptAll(encrypted);
    expect(decrypted.length, 12);
    for (var i = 0; i < 12; i++) {
      expect(decrypted[i].content, 'message number $i');
    }
  });

  test(
    'large batch leaves deletedForEveryone/empty messages untouched by position',
    () async {
      final messages = [
        for (var i = 0; i < 10; i++)
          if (i == 3)
            makeMessage(chatId: 'c', senderId: 'u', content: '', id: 'm$i')
          else if (i == 7)
            makeMessage(
              chatId: 'c',
              senderId: 'u',
              content: 'gone',
              deletedForEveryone: true,
              id: 'm$i',
            )
          else
            makeMessage(
              chatId: 'c',
              senderId: 'u',
              content: 'text $i',
              id: 'm$i',
            ),
      ];

      final encrypted = await encryption.encryptAll(messages);
      expect(encrypted[3].content, '');
      expect(encrypted[7].content, 'gone');
      for (final i in [0, 1, 2, 4, 5, 6, 8, 9]) {
        expect(encrypted[i].content, isNot('text $i'));
      }

      final decrypted = await encryption.decryptAll(encrypted);
      for (final i in [0, 1, 2, 4, 5, 6, 8, 9]) {
        expect(decrypted[i].content, 'text $i');
      }
    },
  );
}
