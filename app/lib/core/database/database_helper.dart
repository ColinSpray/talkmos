import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  static const int _version = 5;
  static const String _dbName = 'chatme.db';

  @visibleForTesting
  static String databaseName = _dbName;

  // ── Table names ────────────────────────────────────────────────────────────
  static const String tableUsers = 'users';
  static const String tableMessages = 'messages';
  static const String tableChats = 'chats';
  static const String tableChatPrefs = 'chat_prefs';

  static const String colChatPrefChatId = 'chat_id';
  static const String colChatPrefMediaVisibility = 'media_visibility';

  static const String colChatId = 'id';
  static const String colChatIsArchived = 'is_archived';
  static const String colChatJson = 'json';
  static const String colChatUpdatedAt = 'updated_at';

  // users columns
  static const String colUserId = 'id';
  static const String colUserName = 'name';
  static const String colUserEmail = 'email';
  static const String colUserPhone = 'phone';
  static const String colUserAvatarUrl = 'avatar_url';
  static const String colUserBio = 'bio';
  static const String colUserLocation = 'location';
  static const String colUserStatus = 'status';
  static const String colUserIsPremium = 'is_premium';
  static const String colUserLastSeenAt = 'last_seen_at';
  static const String colUserToken = 'token';
  static const String colUserFcmToken = 'fcm_token';

  // messages columns
  static const String colMsgMessageId = 'message_id';
  static const String colMsgChatId = 'chat_id';
  static const String colMsgSenderId = 'sender_id';
  static const String colMsgSenderName = 'sender_name';
  static const String colMsgSenderAvatarUrl = 'sender_avatar_url';
  static const String colMsgReceiverId = 'receiver_id';
  static const String colMsgMessageType = 'message_type';
  static const String colMsgContent = 'content'; // encrypted
  static const String colMsgMediaUrl = 'media_url';
  static const String colMsgMediaMime = 'media_mime';
  static const String colMsgMediaFileName = 'media_file_name';
  static const String colMsgMediaSize = 'media_size';
  static const String colMsgMediaDuration = 'media_duration';
  static const String colMsgReplyTo = 'reply_to';
  static const String colMsgStatus = 'status';
  static const String colMsgIsPinned = 'is_pinned';
  static const String colMsgDeletedForAll = 'deleted_for_everyone';
  static const String colMsgForwarded = 'forwarded';
  static const String colMsgEdited = 'edited';
  static const String colMsgCreatedAt = 'created_at';
  static const String colMsgUpdatedAt = 'updated_at';

  // ── Public interface ───────────────────────────────────────────────────────

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  Future<void> wipeAll() async {
    final db = await database;
    final batch = db.batch();
    batch.delete(tableMessages);
    batch.delete(tableChats);
    batch.delete(tableChatPrefs);
    batch.delete(tableUsers);
    await batch.commit(noResult: true);
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createMessagesTable(db);
    await _createMessagesIndexes(db);
    await _createChatsTable(db);
    await _createChatPrefsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS $tableMessages');
      await _createMessagesTable(db);
    }
    if (oldVersion < 3) {
      await _createChatsTable(db);
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS $tableChats');
      await _createChatsTable(db);
    }
    if (oldVersion < 5) {
      await _createChatPrefsTable(db);
    }
    // Idempotent — safe to run on every upgrade regardless of which
    // version introduced it, so an existing v3 install picks it up too.
    await _createMessagesIndexes(db);
  }

  Future<void> _createUsersTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS $tableUsers (
      $colUserId          TEXT PRIMARY KEY NOT NULL,
      $colUserName        TEXT NOT NULL,
      $colUserEmail       TEXT,
      $colUserPhone       TEXT,
      $colUserAvatarUrl   TEXT,
      $colUserBio         TEXT,
      $colUserLocation    TEXT,
      $colUserStatus      TEXT,
      $colUserIsPremium   INTEGER NOT NULL DEFAULT 0,
      $colUserLastSeenAt  TEXT,
      $colUserToken       TEXT,
      $colUserFcmToken    TEXT
    )
  ''');

  Future<void> _createMessagesTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS $tableMessages (
      $colMsgMessageId        TEXT PRIMARY KEY NOT NULL,
      $colMsgChatId           TEXT NOT NULL DEFAULT '',
      $colMsgSenderId         TEXT NOT NULL,
      $colMsgSenderName       TEXT NOT NULL DEFAULT '',
      $colMsgSenderAvatarUrl  TEXT NOT NULL DEFAULT '',
      $colMsgReceiverId       TEXT NOT NULL DEFAULT '',
      $colMsgMessageType      TEXT NOT NULL DEFAULT 'text',
      $colMsgContent          TEXT NOT NULL DEFAULT '',
      $colMsgMediaUrl         TEXT NOT NULL DEFAULT '',
      $colMsgMediaMime        TEXT NOT NULL DEFAULT '',
      $colMsgMediaFileName    TEXT NOT NULL DEFAULT '',
      $colMsgMediaSize        INTEGER NOT NULL DEFAULT 0,
      $colMsgMediaDuration    INTEGER NOT NULL DEFAULT 0,
      $colMsgReplyTo          TEXT,
      $colMsgStatus           TEXT NOT NULL DEFAULT 'sent',
      $colMsgIsPinned         INTEGER NOT NULL DEFAULT 0,
      $colMsgDeletedForAll    INTEGER NOT NULL DEFAULT 0,
      $colMsgForwarded        INTEGER NOT NULL DEFAULT 0,
      $colMsgEdited           INTEGER NOT NULL DEFAULT 0,
      $colMsgCreatedAt        TEXT NOT NULL,
      $colMsgUpdatedAt        TEXT NOT NULL
    )
  ''');

  Future<void> _createMessagesIndexes(Database db) => db.execute(
    'CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON $tableMessages ($colMsgChatId, $colMsgCreatedAt)',
  );

  Future<void> _createChatsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableChats (
        $colChatId          TEXT PRIMARY KEY NOT NULL,
        $colChatIsArchived  INTEGER NOT NULL DEFAULT 0,
        $colChatJson        TEXT NOT NULL,
        $colChatUpdatedAt   TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chats_archived ON $tableChats ($colChatIsArchived)',
    );
  }

  Future<void> _createChatPrefsTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS $tableChatPrefs (
      $colChatPrefChatId           TEXT PRIMARY KEY NOT NULL,
      $colChatPrefMediaVisibility  INTEGER
    )
  ''');
}
