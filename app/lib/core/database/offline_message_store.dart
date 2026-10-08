import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../encryption/ciphertext_envelope.dart';
import '../encryption/local_db_cipher.dart';
import '../encryption/crypto_isolate.dart';
import '../../models/chat_message_model.dart';
import '../../models/recent_chat.dart';

class OfflineMessageStore {
  OfflineMessageStore._();
  static final OfflineMessageStore instance = OfflineMessageStore._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── Messages: Write ────────────────────────────────────────────────────────

  Future<void> save(ChatMessageModel message, String currentUserId) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableMessages,
      await _toRow(message, currentUserId),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> upsert(ChatMessageModel message, String currentUserId) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableMessages,
      await _toRow(message, currentUserId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveAll(
    List<ChatMessageModel> messages,
    String currentUserId,
  ) async {
    if (messages.isEmpty) return;
    final rows = await _toRowsBatch(messages, currentUserId);
    final db = await _db.database;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(
        DatabaseHelper.tableMessages,
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateStatus(String messageId, MessageStatus status) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableMessages,
      {DatabaseHelper.colMsgStatus: status.name},
      where: '${DatabaseHelper.colMsgMessageId} = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> markDeletedForEveryone(String messageId) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableMessages,
      {DatabaseHelper.colMsgDeletedForAll: 1, DatabaseHelper.colMsgContent: ''},
      where: '${DatabaseHelper.colMsgMessageId} = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> delete(String messageId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableMessages,
      where: '${DatabaseHelper.colMsgMessageId} = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessagesForChat(String chatId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableMessages,
      where: '${DatabaseHelper.colMsgChatId} = ?',
      whereArgs: [chatId],
    );
  }

  // ── Messages: Read ─────────────────────────────────────────────────────────

  Future<List<ChatMessageModel>> getMessages(
    String chatId,
    String currentUserId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableMessages,
      where: '${DatabaseHelper.colMsgChatId} = ?',
      whereArgs: [chatId],
      orderBy: '${DatabaseHelper.colMsgCreatedAt} DESC',
      limit: limit,
      offset: offset,
    );
    final ordered = rows.reversed.toList();
    final decryptedContents = await _decryptRowsBatch(ordered, currentUserId);
    return [
      for (var i = 0; i < ordered.length; i++)
        _fromRow(ordered[i], decryptedContents[i]),
    ];
  }

  Future<bool> hasMessages(String chatId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM ${DatabaseHelper.tableMessages} '
      'WHERE ${DatabaseHelper.colMsgChatId} = ?',
      [chatId],
    );
    return ((result.first['cnt'] as int?) ?? 0) > 0;
  }

  // ── Chats: Write ───────────────────────────────────────────────────────────

  Future<void> saveChats(
    List<RecentChat> chats, {
    required bool archived,
  }) async {
    if (chats.isEmpty) return;
    final db = await _db.database;
    final batch = db.batch();
    for (final chat in chats) {
      batch.insert(DatabaseHelper.tableChats, {
        DatabaseHelper.colChatId: chat.id,
        DatabaseHelper.colChatIsArchived: archived ? 1 : 0,
        DatabaseHelper.colChatJson: jsonEncode(chat.toJson()),
        DatabaseHelper.colChatUpdatedAt: DateTime.now()
            .toUtc()
            .toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Removes a single chat from the cache — mirrors "delete chat" clearing
  /// it from the live list, so the cache doesn't resurrect it on next launch.
  Future<void> removeCachedChat(String chatId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableChats,
      where: '${DatabaseHelper.colChatId} = ?',
      whereArgs: [chatId],
    );
  }

  // ── Chats: Read ────────────────────────────────────────────────────────────

  Future<List<RecentChat>> getCachedChats({required bool archived}) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableChats,
      where: '${DatabaseHelper.colChatIsArchived} = ?',
      whereArgs: [archived ? 1 : 0],
      orderBy: '${DatabaseHelper.colChatUpdatedAt} DESC',
    );
    final result = <RecentChat>[];
    for (final row in rows) {
      try {
        final json = jsonDecode(row[DatabaseHelper.colChatJson] as String);
        result.add(RecentChat.fromJson(json as Map<String, dynamic>));
      } catch (_) {
        // Skip a row that no longer matches RecentChat's shape (e.g. after
        // a model field change) rather than let one bad row break the list.
      }
    }
    return result;
  }

  /// Decrypts every row's content, in the same order as [rows].
  Future<List<String>> _decryptRowsBatch(
    List<Map<String, dynamic>> rows,
    String currentUserId,
  ) async {
    final results = List<String>.filled(rows.length, '');
    final workIndices = <int>[
      for (var i = 0; i < rows.length; i++)
        if ((rows[i][DatabaseHelper.colMsgDeletedForAll] as int? ?? 0) != 1 &&
            (rows[i][DatabaseHelper.colMsgContent] as String).isNotEmpty)
          i,
    ];
    if (workIndices.isEmpty) return results;

    if (workIndices.length < cryptoIsolateThreshold) {
      for (final i in workIndices) {
        final encrypted = rows[i][DatabaseHelper.colMsgContent] as String;
        final senderId = rows[i][DatabaseHelper.colMsgSenderId] as String;
        try {
          results[i] = await LocalDbCipher.decrypt(
            encrypted,
            legacyUserId: currentUserId,
            legacySenderId: senderId,
          );
        } catch (_) {
          results[i] = encrypted;
        }
      }
      return results;
    }

    // Keyed per item, because a store part-way through the migration holds
    // rows under both the old bundled salt and the device key.
    final items = <Map<String, String>>[];
    for (final i in workIndices) {
      final envelope = CiphertextEnvelope.parse(
        rows[i][DatabaseHelper.colMsgContent] as String,
      );
      items.add({
        'id': '$i',
        'content': envelope.payload,
        'key': await LocalDbCipher.keyForRead(
          envelope,
          legacyUserId: currentUserId,
          legacySenderId: rows[i][DatabaseHelper.colMsgSenderId] as String,
        ),
      });
    }

    final byIndex = await compute(decryptBatch, items);
    for (final i in workIndices) {
      results[i] =
          byIndex['$i'] ?? (rows[i][DatabaseHelper.colMsgContent] as String);
    }
    return results;
  }

  /// Builds every row for [messages], encrypting content the same
  /// isolate-offload way as [_decryptRowsBatch].
  Future<List<Map<String, dynamic>>> _toRowsBatch(
    List<ChatMessageModel> messages,
    String currentUserId,
  ) async {
    final rows = [for (final m in messages) _rowFields(m, '')];
    final workIndices = <int>[
      for (var i = 0; i < messages.length; i++)
        if (!messages[i].deletedForEveryone && messages[i].content.isNotEmpty)
          i,
    ];
    if (workIndices.isEmpty) return rows;

    if (workIndices.length < cryptoIsolateThreshold) {
      for (final i in workIndices) {
        rows[i][DatabaseHelper.colMsgContent] = await LocalDbCipher.encrypt(
          messages[i].content,
        );
      }
      return rows;
    }

    // One key for every row on the way in — the device key. Only reads have
    // to cope with a mix.
    final localKey = await LocalDbCipher.keyForWrite();
    final items = [
      for (final i in workIndices)
        {'id': '$i', 'content': messages[i].content, 'key': localKey},
    ];
    final byIndex = await compute(encryptBatch, items);
    for (final i in workIndices) {
      final payload = byIndex['$i'];
      rows[i][DatabaseHelper.colMsgContent] = payload == null
          ? ''
          : CiphertextEnvelope.wrap(
              keyId: LocalDbCipher.keyId,
              payload: payload,
            );
    }
    return rows;
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _toRow(
    ChatMessageModel m,
    String currentUserId,
  ) async {
    final encryptedContent = m.deletedForEveryone || m.content.isEmpty
        ? ''
        : await LocalDbCipher.encrypt(m.content);
    return _rowFields(m, encryptedContent);
  }

  Map<String, dynamic> _rowFields(
    ChatMessageModel m,
    String encryptedContent,
  ) => {
    DatabaseHelper.colMsgMessageId: m.id,
    DatabaseHelper.colMsgChatId: m.chatId,
    DatabaseHelper.colMsgSenderId: m.senderId,
    DatabaseHelper.colMsgSenderName: m.senderName,
    DatabaseHelper.colMsgSenderAvatarUrl: m.senderAvatarUrl,
    DatabaseHelper.colMsgReceiverId: m.receiverId,
    DatabaseHelper.colMsgMessageType: m.messageType.name,
    DatabaseHelper.colMsgContent: encryptedContent,
    DatabaseHelper.colMsgMediaUrl: m.media.url,
    DatabaseHelper.colMsgMediaMime: m.media.mimeType,
    DatabaseHelper.colMsgMediaFileName: m.media.fileName,
    DatabaseHelper.colMsgMediaSize: m.media.size,
    DatabaseHelper.colMsgMediaDuration: m.media.duration,
    DatabaseHelper.colMsgReplyTo: m.replyTo,
    DatabaseHelper.colMsgStatus: m.status.name,
    DatabaseHelper.colMsgIsPinned: m.isPinned ? 1 : 0,
    DatabaseHelper.colMsgDeletedForAll: m.deletedForEveryone ? 1 : 0,
    DatabaseHelper.colMsgForwarded: m.forwarded ? 1 : 0,
    DatabaseHelper.colMsgEdited: m.edited ? 1 : 0,
    DatabaseHelper.colMsgCreatedAt: m.createdAt.toUtc().toIso8601String(),
    DatabaseHelper.colMsgUpdatedAt: m.updatedAt.toUtc().toIso8601String(),
  };

  ChatMessageModel _fromRow(Map<String, dynamic> row, String content) {
    final deletedForAll =
        (row[DatabaseHelper.colMsgDeletedForAll] as int? ?? 0) == 1;

    return ChatMessageModel(
      id: row[DatabaseHelper.colMsgMessageId] as String,
      chatId: row[DatabaseHelper.colMsgChatId] as String,
      senderId: row[DatabaseHelper.colMsgSenderId] as String,
      senderName: row[DatabaseHelper.colMsgSenderName] as String,
      senderAvatarUrl: row[DatabaseHelper.colMsgSenderAvatarUrl] as String,
      receiverId: row[DatabaseHelper.colMsgReceiverId] as String,
      messageType: ChatMessageModel.messageTypeFromString(
        row[DatabaseHelper.colMsgMessageType] as String?,
      ),
      content: deletedForAll ? '' : content,
      media: MessageMedia(
        url: row[DatabaseHelper.colMsgMediaUrl] as String,
        mimeType: row[DatabaseHelper.colMsgMediaMime] as String,
        fileName: row[DatabaseHelper.colMsgMediaFileName] as String,
        size: row[DatabaseHelper.colMsgMediaSize] as int,
        duration: row[DatabaseHelper.colMsgMediaDuration] as int,
      ),
      replyTo: row[DatabaseHelper.colMsgReplyTo] as String?,
      mentions: const [],
      forwarded: (row[DatabaseHelper.colMsgForwarded] as int? ?? 0) == 1,
      edited: (row[DatabaseHelper.colMsgEdited] as int? ?? 0) == 1,
      status: ChatMessageModel.statusFromString(
        row[DatabaseHelper.colMsgStatus] as String?,
      ),
      isPinned: (row[DatabaseHelper.colMsgIsPinned] as int? ?? 0) == 1,
      deletedForEveryone: deletedForAll,
      deletedForMe: const [],
      createdAt: DateTime.parse(
        row[DatabaseHelper.colMsgCreatedAt] as String,
      ).toLocal(),
      updatedAt: DateTime.parse(
        row[DatabaseHelper.colMsgUpdatedAt] as String,
      ).toLocal(),
    );
  }
}
