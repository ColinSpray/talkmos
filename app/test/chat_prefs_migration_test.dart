import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talkmos/core/database/database_helper.dart';
import 'package:talkmos/core/services/media_visibility_store.dart';

/// Exercises the v4 -> v5 upgrade an existing install goes through when it
/// picks up per-chat media visibility, rather than the clean v5 create that
/// a fresh install gets.
void main() {
  late String dbPath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Own database file — see DatabaseHelper.databaseName.
    DatabaseHelper.databaseName = 'test_chat_prefs_migration.db';
    dbPath = p.join(await getDatabasesPath(), DatabaseHelper.databaseName);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.instance.close();
    await databaseFactory.deleteDatabase(dbPath);
    MediaVisibilityStore.instance.reset();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
    await databaseFactory.deleteDatabase(dbPath);
  });

  /// The schema as it stood at v4: no chat_prefs table, chats already a JSON
  /// blob. Built by hand so the upgrade runs against a real old database
  /// instead of a freshly-created new one.
  Future<void> createV4Database() async {
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY NOT NULL,
              name TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE messages (
              message_id TEXT PRIMARY KEY NOT NULL,
              chat_id TEXT NOT NULL DEFAULT '',
              sender_id TEXT NOT NULL,
              content TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE chats (
              id TEXT PRIMARY KEY NOT NULL,
              is_archived INTEGER NOT NULL DEFAULT 0,
              json TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    // Some cached data, to prove the upgrade doesn't take it out.
    await db.insert('chats', {
      'id': 'chat-1',
      'is_archived': 0,
      'json': '{"id":"chat-1"}',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });
    await db.insert('messages', {
      'message_id': 'm1',
      'chat_id': 'chat-1',
      'sender_id': 'u1',
      'content': 'hello',
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });
    await db.close();
  }

  test('upgrading from v4 adds chat_prefs and keeps cached data', () async {
    await createV4Database();

    final db = await DatabaseHelper.instance.database;

    expect(await db.getVersion(), 5);

    // The new table exists and starts empty — every existing chat therefore
    // reads as followGlobal, which with the global switch off means an
    // upgrading install keeps its current no-saving behaviour.
    final prefs = await db.query(DatabaseHelper.tableChatPrefs);
    expect(prefs, isEmpty);

    expect(
      (await db.query(DatabaseHelper.tableChats)).single['id'],
      'chat-1',
      reason: 'the upgrade must not drop the chats cache',
    );
    expect((await db.query(DatabaseHelper.tableMessages)).length, 1);
  });

  test('an upgraded install defaults to not saving', () async {
    await createV4Database();
    await DatabaseHelper.instance.database;

    await MediaVisibilityStore.instance.load();
    expect(MediaVisibilityStore.instance.shouldSaveFor('chat-1'), isFalse);
  });

  test('overrides are writable straight after the upgrade', () async {
    await createV4Database();
    await DatabaseHelper.instance.database;
    await MediaVisibilityStore.instance.load();

    await MediaVisibilityStore.instance.setVisibilityFor(
      'chat-1',
      MediaVisibility.always,
    );

    MediaVisibilityStore.instance.reset();
    await MediaVisibilityStore.instance.load();
    expect(
      MediaVisibilityStore.instance.visibilityFor('chat-1'),
      MediaVisibility.always,
    );
  });

  test(
    'the messages index is (re)created without a messages table wipe',
    () async {
      await createV4Database();
      final db = await DatabaseHelper.instance.database;

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = ?",
        [DatabaseHelper.tableMessages],
      );
      expect(indexes.map((r) => r['name']), contains('idx_messages_chat_id'));
    },
  );
}
