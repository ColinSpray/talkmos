import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_endpoints.dart';
import 'http_key_client.dart';

/// What the server says a message key is made of.
class MessageKeyFormula {
  /// Which key this is. Stored with every ciphertext so a rotation does not
  /// strand the messages written before it.
  final int keyId;

  /// The derivation, with `{userId}` and `{chatId}` left to substitute.
  final String template;

  final String salt;

  const MessageKeyFormula({
    required this.keyId,
    required this.template,
    required this.salt,
  });

  /// The legacy scheme: the salt that used to ship inside the app bundle.
  /// Everything written before this change is under keyId 0.
  static const legacyKeyId = 0;

  String keyFor({required String userId, required String chatId}) => template
      .replaceAll('{userId}', userId)
      .replaceAll('{salt}', salt)
      .replaceAll('{chatId}', chatId);

  Map<String, dynamic> toJson() => {
    'keyId': keyId,
    'template': template,
    'salt': salt,
  };

  static MessageKeyFormula? fromJson(Map<String, dynamic> json) {
    final template = json['template']?.toString();
    final salt = json['salt']?.toString();
    final keyId = json['keyId'];
    if (template == null || template.isEmpty) return null;
    if (salt == null || salt.isEmpty) return null;
    if (keyId is! int) return null;
    return MessageKeyFormula(keyId: keyId, template: template, salt: salt);
  }
}

/// Fetches the message key formula and keeps it available.
///
/// Cached in the keystore as well as in memory, because the app has to be able
/// to read its own history on a cold start with no network — and because the
/// FCM background isolate decrypts without ever reaching a screen that could
/// report a failed fetch.
class MessageKeyService {
  MessageKeyService._();
  static final MessageKeyService instance = MessageKeyService._();

  static const _storageKey = 'talkmos_message_key_formula_v1';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @visibleForTesting
  static KeyHttpClient client = const KeyHttpClient();

  MessageKeyFormula? _cached;
  Future<MessageKeyFormula?>? _inFlight;

  /// The current formula, or null if one has never been obtained.
  ///
  /// Never throws: a caller that cannot get a key has to fall back to the
  /// legacy one rather than lose the message.
  Future<MessageKeyFormula?> get() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _inFlight ??= _resolve().whenComplete(() => _inFlight = null);
  }

  /// What is already known, without a fetch or a disk read. For the paths that
  /// cannot await — an encrypt inside a synchronous build, say.
  MessageKeyFormula? get cached => _cached;

  Future<MessageKeyFormula?> _resolve() async {
    final stored = await _readStored();
    if (stored != null) {
      _cached = stored;
      // Refreshed in the background so a rotation is picked up by the next
      // launch without this one waiting on the network.
      unawaited(_fetchAndStore());
      return stored;
    }
    return _fetchAndStore();
  }

  /// Pulls a fresh formula and replaces the cached one. Called on sign-in and
  /// whenever a rotation needs picking up promptly.
  Future<MessageKeyFormula?> refresh() => _fetchAndStore();

  Future<MessageKeyFormula?> _fetchAndStore() async {
    try {
      final body = await client.getJson(ApiEndpoints.messageKey);
      if (body == null || body['success'] != true) return _cached;

      final data = body['data'];
      if (data is! Map<String, dynamic>) return _cached;

      final formula = MessageKeyFormula.fromJson(data);
      if (formula == null) {
        debugPrint('[MessageKey] server sent an unusable formula');
        return _cached;
      }

      _cached = formula;
      await _writeStored(formula);
      return formula;
    } catch (e) {
      debugPrint('[MessageKey] fetch failed: $e');
      return _cached;
    }
  }

  Future<MessageKeyFormula?> _readStored() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return MessageKeyFormula.fromJson(decoded);
    } catch (e) {
      debugPrint('[MessageKey] cache read failed: $e');
      return null;
    }
  }

  Future<void> _writeStored(MessageKeyFormula formula) async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(formula.toJson()),
      );
    } catch (e) {
      debugPrint('[MessageKey] cache write failed: $e');
    }
  }

  /// Forgets the formula. Belongs with sign-out — the next account gets its
  /// own, and this one's should not be sitting on the device meanwhile.
  Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _storageKey);
    } catch (e) {
      debugPrint('[MessageKey] cache delete failed: $e');
    }
  }

  @visibleForTesting
  void seedForTest(MessageKeyFormula? formula) => _cached = formula;
}
