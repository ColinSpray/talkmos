import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The key the local message store is encrypted with.
///
/// Generated on the device, kept in the platform keystore, and never sent
/// anywhere. It is deliberately not the message key: that one comes from the
/// server and the server can therefore read anything encrypted with it, while
/// this one exists so that a copy of `local.db` — pulled off a rooted phone or
/// out of a backup — is not readable without also breaking the keystore.
class LocalDbKey {
  LocalDbKey._();
  static final LocalDbKey instance = LocalDbKey._();

  static const _storageKey = 'talkmos_local_db_key_v1';
  static const _keyBytes = 32;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      // Not `whenUnlocked`: the FCM background isolate has to decrypt queued
      // messages while the phone is sitting locked in a pocket.
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Held for the process lifetime once read. Every message written or read
  /// goes through this, so a keystore round trip per row is not affordable.
  String? _cached;

  /// Concurrent callers on a cold start must not each generate a key and race
  /// to persist a different one.
  Future<String>? _inFlight;

  /// The key, as the string the cipher derives from.
  Future<String> get() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<String> _load() async {
    try {
      final existing = await _storage.read(key: _storageKey);
      if (existing != null && existing.isNotEmpty) {
        _cached = existing;
        return existing;
      }
    } catch (e) {
      // A keystore that cannot be read is usually a device whose credentials
      // changed under it. Falling through generates a fresh key, which loses
      // the old rows rather than locking the app out of its own database.
      debugPrint('[LocalDbKey] keystore read failed: $e');
    }

    final generated = _generate();
    try {
      await _storage.write(key: _storageKey, value: generated);
    } catch (e) {
      debugPrint('[LocalDbKey] keystore write failed: $e');
    }
    _cached = generated;
    return generated;
  }

  /// 256 bits from the platform CSPRNG.
  String _generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(_keyBytes, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Drops the key from memory and the keystore.
  ///
  /// Everything in the local store becomes unreadable, so this belongs with a
  /// wipe of that store — on sign-out — and nowhere else.
  Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _storageKey);
    } catch (e) {
      debugPrint('[LocalDbKey] keystore delete failed: $e');
    }
  }

  @visibleForTesting
  void resetCacheForTest() => _cached = null;

  @visibleForTesting
  void seedForTest(String key) => _cached = key;
}
