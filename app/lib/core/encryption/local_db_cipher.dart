import 'ciphertext_envelope.dart';
import 'encryption_helper.dart';
import 'local_db_key.dart';
import 'talkmos_encryption.dart';

/// Encrypts message bodies on their way into the local store.
///
/// Separate from the message key on purpose. That one comes from the server,
/// so anything encrypted with it is readable by the server; this one is
/// generated on the device and never leaves it, so a copy of `local.db` lifted
/// off a rooted phone or out of a backup is not readable on its own.
class LocalDbCipher {
  LocalDbCipher._();

  /// Generation of the on-device key. Bumped only if the key scheme changes —
  /// rotating the key itself would strand every row already written.
  static const int keyId = 1;

  static Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) return plaintext;
    final key = await LocalDbKey.instance.get();
    return CiphertextEnvelope.wrap(
      keyId: keyId,
      payload: await EncryptionHelper.encrypt(plaintext, key),
    );
  }

  /// Reads a row back.
  ///
  /// [legacyUserId] and [legacySenderId] reconstruct the pre-migration key for
  /// rows written before the local key existed. They are only touched for
  /// untagged values, so a store with no history left never derives it.
  static Future<String> decrypt(
    String stored, {
    required String legacyUserId,
    required String legacySenderId,
  }) async {
    if (stored.isEmpty) return stored;
    final envelope = CiphertextEnvelope.parse(stored);

    if (envelope.keyId == CiphertextEnvelope.legacyKeyId) {
      return TalkmosEncryption(
        userId: legacyUserId,
        senderId: legacySenderId,
      ).decrypt(envelope.payload);
    }
    final key = await LocalDbKey.instance.get();
    return EncryptionHelper.decrypt(envelope.payload, key);
  }

  /// The key a batch item should be encrypted or decrypted under, for the
  /// isolate paths that take a key per item rather than calling in here.
  static Future<String> keyForWrite() => LocalDbKey.instance.get();

  static Future<String> keyForRead(
    CiphertextEnvelope envelope, {
    required String legacyUserId,
    required String legacySenderId,
  }) async {
    if (envelope.keyId == CiphertextEnvelope.legacyKeyId) {
      return TalkmosEncryption(
        userId: legacyUserId,
        senderId: legacySenderId,
      ).secretKey;
    }
    return LocalDbKey.instance.get();
  }
}
