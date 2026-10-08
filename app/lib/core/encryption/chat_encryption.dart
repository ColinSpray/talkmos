import 'package:flutter/foundation.dart' show compute;
import '../../models/chat_message_model.dart';
import 'talkmos_encryption.dart';
import 'crypto_isolate.dart';

class ChatEncryption {
  ChatEncryption._();
  static final ChatEncryption instance = ChatEncryption._();

  Future<String> encryptContent(
    String content, {
    required String senderId,
    required String chatId,
  }) async {
    if (content.isEmpty) return content;
    return TalkmosEncryption(
      userId: senderId,
      senderId: chatId,
    ).encrypt(content);
  }

  Future<String> decryptContent(
    String content, {
    required String senderId,
    required String chatId,
  }) async {
    if (content.isEmpty) return content;
    try {
      return await TalkmosEncryption(
        userId: senderId,
        senderId: chatId,
      ).decrypt(content);
    } catch (_) {
      return content;
    }
  }

  Future<ChatMessageModel> encrypt(ChatMessageModel message) async {
    if (message.content.isEmpty || message.deletedForEveryone) return message;
    final encrypted = await encryptContent(
      message.content,
      senderId: message.senderId,
      chatId: message.chatId,
    );
    return message.copyWith(content: encrypted);
  }

  /// Returns a copy of [message] with its content decrypted.
  /// Falls back to the original content if decryption fails.
  Future<ChatMessageModel> decrypt(ChatMessageModel message) async {
    if (message.content.isEmpty || message.deletedForEveryone) return message;
    final decrypted = await decryptContent(
      message.content,
      senderId: message.senderId,
      chatId: message.chatId,
    );
    return message.copyWith(content: decrypted);
  }

  Future<List<ChatMessageModel>> encryptAll(List<ChatMessageModel> messages) =>
      _runBatch(messages, encrypt, encryptBatch);

  /// Decrypts a list of messages — same isolate-offload strategy as
  /// [encryptAll].
  Future<List<ChatMessageModel>> decryptAll(List<ChatMessageModel> messages) =>
      _runBatch(messages, decrypt, decryptBatch);

  Future<List<ChatMessageModel>> _runBatch(
    List<ChatMessageModel> messages,
    Future<ChatMessageModel> Function(ChatMessageModel) inlineOp,
    Future<Map<String, String>> Function(List<Map<String, String>>) isolateOp,
  ) async {
    if (messages.isEmpty) return messages;

    final workIndices = <int>[
      for (var i = 0; i < messages.length; i++)
        if (messages[i].content.isNotEmpty && !messages[i].deletedForEveryone)
          i,
    ];
    if (workIndices.isEmpty) return messages;

    if (workIndices.length < cryptoIsolateThreshold) {
      final result = List<ChatMessageModel>.from(messages);
      for (final i in workIndices) {
        result[i] = await inlineOp(messages[i]);
      }
      return result;
    }

    final items = [
      for (final i in workIndices)
        {
          'id': '$i',
          'content': messages[i].content,
          'key':
              '${messages[i].senderId}${TalkmosEncryption.key}${messages[i].chatId}',
        },
    ];
    final byIndex = await compute(isolateOp, items);

    final result = List<ChatMessageModel>.from(messages);
    for (final i in workIndices) {
      final processed = byIndex['$i'];
      if (processed != null)
        result[i] = messages[i].copyWith(content: processed);
    }
    return result;
  }
}
