import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'encryption_helper.dart';

class TalkmosEncryption {
  static String get key {
    final salt = dotenv.env['ENCRYPTION_KEY'];
    if (salt != null && salt.isNotEmpty) {
      return salt;
    }
    throw Exception('BACKEND_URL not configured in .env file');
  }

  final String userId;
  final String senderId;

  TalkmosEncryption({required this.userId, required this.senderId});

  /// Derives the secret key string: userId + salt + senderId
  String get secretKey => '$userId$key$senderId';

  /// Encrypts plaintext message.
  Future<String> encrypt(String plaintext) async {
    return EncryptionHelper.encrypt(plaintext, secretKey);
  }

  /// Decrypts encrypted message data.
  Future<String> decrypt(String encryptedData) async {
    return EncryptionHelper.decrypt(encryptedData, secretKey);
  }

  /// Static helper to encrypt with explicit key parts.
  static Future<String> encryptWithKey({
    required String plaintext,
    required String userId,
    required String senderId,
  }) async {
    final key = '$userId${TalkmosEncryption.key}$senderId';
    return EncryptionHelper.encrypt(plaintext, key);
  }

  /// Static helper to decrypt with explicit key parts.
  static Future<String> decryptWithKey({
    required String encryptedData,
    required String userId,
    required String senderId,
  }) async {
    // Braces matter: without them this interpolated the type's name followed
    // by a literal ".key", deriving a key that could never undo
    // [encryptWithKey].
    final key = '$userId${TalkmosEncryption.key}$senderId';
    return EncryptionHelper.decrypt(encryptedData, key);
  }
}
