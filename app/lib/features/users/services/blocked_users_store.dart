import 'package:shared_preferences/shared_preferences.dart';

class BlockedUsersStore {
  const BlockedUsersStore._();

  static const _key = 'blocked_user_ids';

  static Set<String> _cache = <String>{};

  static bool isBlocked(String userId) =>
      userId.isNotEmpty && _cache.contains(userId);

  /// Disk read, for the FCM background isolate where [_cache] is always empty.
  static Future<bool> isBlockedOnDisk(String userId) async {
    if (userId.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_key) ?? const []).contains(userId);
    } catch (_) {
      // Never let a prefs failure swallow a call or message.
      return false;
    }
  }

  /// Pulls the disk copy into memory so the synchronous check works before the
  /// first network load returns. Cheap; called once at startup.
  static Future<void> warmUp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cache = (prefs.getStringList(_key) ?? const []).toSet();
    } catch (_) {
      _cache = <String>{};
    }
  }

  /// Replaces the whole mirror. Called whenever [BlockProvider] has a fresh
  /// view of who's blocked.
  static Future<void> sync(Iterable<String> userIds) async {
    _cache = userIds.toSet();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _cache.toList());
    } catch (_) {
      // In-memory copy is already updated; the disk copy catches up on the
      // next sync. Worst case the background isolate is one block behind.
    }
  }

  /// Drops everything — the mirror belongs to one account.
  static Future<void> clear() => sync(const <String>[]);
}
