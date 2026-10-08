import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talkmos/core/database/database_helper.dart';
import 'package:talkmos/core/services/media_visibility_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Own database file — see DatabaseHelper.databaseName.
    DatabaseHelper.databaseName = 'test_media_visibility.db';
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.instance.wipeAll();
    MediaVisibilityStore.instance.reset();
    await MediaVisibilityStore.instance.load();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  final store = MediaVisibilityStore.instance;

  group('defaults', () {
    test('global switch is off, so nothing saves out of the box', () async {
      expect(store.saveToPhotos, isFalse);
      expect(store.shouldSaveFor('chat-1'), isFalse);
    });

    test('a chat with no override reports followGlobal', () {
      expect(store.visibilityFor('chat-1'), MediaVisibility.followGlobal);
    });
  });

  group('global switch', () {
    test('turning it on makes un-overridden chats save', () async {
      await store.setSaveToPhotos(true);
      expect(store.shouldSaveFor('chat-1'), isTrue);
    });

    test(
      'followGlobal tracks later changes rather than pinning a value',
      () async {
        await store.setSaveToPhotos(true);
        expect(store.shouldSaveFor('chat-1'), isTrue);
        await store.setSaveToPhotos(false);
        expect(store.shouldSaveFor('chat-1'), isFalse);
      },
    );
  });

  group('per-chat overrides', () {
    test('never wins over a global switch that is on', () async {
      await store.setSaveToPhotos(true);
      await store.setVisibilityFor('quiet', MediaVisibility.never);

      expect(store.shouldSaveFor('quiet'), isFalse);
      expect(store.shouldSaveFor('other'), isTrue, reason: 'unaffected chat');
    });

    test('always wins over a global switch that is off', () async {
      await store.setVisibilityFor('family', MediaVisibility.always);

      expect(store.shouldSaveFor('family'), isTrue);
      expect(store.shouldSaveFor('other'), isFalse);
    });

    test('resetting to followGlobal removes the override entirely', () async {
      await store.setVisibilityFor('c', MediaVisibility.always);
      await store.setVisibilityFor('c', MediaVisibility.followGlobal);

      expect(store.visibilityFor('c'), MediaVisibility.followGlobal);
      expect(store.shouldSaveFor('c'), isFalse);

      // Absence, not a stored third value — the row should be gone.
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(DatabaseHelper.tableChatPrefs);
      expect(rows, isEmpty);
    });

    test('overrides survive a reload from disk', () async {
      await store.setVisibilityFor('a', MediaVisibility.always);
      await store.setVisibilityFor('b', MediaVisibility.never);
      await store.setSaveToPhotos(true);

      // Force a genuine re-read rather than trusting the in-memory mirror.
      store.reset();
      await store.load();

      expect(store.visibilityFor('a'), MediaVisibility.always);
      expect(store.visibilityFor('b'), MediaVisibility.never);
      expect(store.shouldSaveFor('a'), isTrue);
      expect(store.shouldSaveFor('b'), isFalse);
    });

    test('an empty chat id is ignored rather than stored', () async {
      await store.setVisibilityFor('', MediaVisibility.always);
      final db = await DatabaseHelper.instance.database;
      expect(await db.query(DatabaseHelper.tableChatPrefs), isEmpty);
    });
  });

  group('account switch', () {
    test('wipeAll clears the rows and reset clears the mirror', () async {
      await store.setVisibilityFor('a', MediaVisibility.always);

      await DatabaseHelper.instance.wipeAll();
      store.reset();
      await store.load();

      expect(store.visibilityFor('a'), MediaVisibility.followGlobal);
    });

    test('the global switch is a device setting and survives reset', () async {
      await store.setSaveToPhotos(true);
      store.reset();

      expect(
        store.saveToPhotos,
        isTrue,
        reason: 'clearing it would desync from SharedPreferences',
      );
    });
  });

  group('failure modes', () {
    test(
      'nothing saves before a successful load, even with the global on',
      () async {
        await store.setSaveToPhotos(true);
        await store.setVisibilityFor('quiet', MediaVisibility.never);

        // Stand-in for a failed overrides read: the mirror is empty and unproven.
        // 'quiet' must not start saving just because its override is unreadable.
        store.reset();

        expect(store.shouldSaveFor('quiet'), isFalse);
        expect(store.shouldSaveFor('anything'), isFalse);
      },
    );

    test('saving resumes once the overrides are actually loaded', () async {
      await store.setSaveToPhotos(true);
      store.reset();
      expect(store.shouldSaveFor('c'), isFalse);

      await store.load();
      expect(store.shouldSaveFor('c'), isTrue);
    });
  });

  group('chats-table independence', () {
    test('a conversations-list refresh cannot reset an override', () async {
      await store.setVisibilityFor('chat-1', MediaVisibility.never);

      // What saveChats does after every getConversations fetch: replace the
      // cached row for this chat wholesale. An override living on the chats
      // table would be reset to its default here.
      final db = await DatabaseHelper.instance.database;
      await db.insert(DatabaseHelper.tableChats, {
        DatabaseHelper.colChatId: 'chat-1',
        DatabaseHelper.colChatIsArchived: 0,
        DatabaseHelper.colChatJson: '{}',
        DatabaseHelper.colChatUpdatedAt: DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      store.reset();
      await store.load();
      expect(store.visibilityFor('chat-1'), MediaVisibility.never);
    });
  });
}
