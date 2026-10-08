import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptionHelper {
  static final _algorithm = AesGcm.with256bits();

  static Future<SecretKey> _deriveKey(String secretKeyStr) async {
    final keyBytes = utf8.encode(secretKeyStr);
    final hash = await Sha256().hash(keyBytes);
    return SecretKey(hash.bytes);
  }

  static Future<String> encrypt(String plaintext, String secretKeyStr) async {
    final secretKey = await _deriveKey(secretKeyStr);
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
    );

    final nonceB64 = base64.encode(secretBox.nonce);
    final macB64 = base64.encode(secretBox.mac.bytes);
    final cipherTextB64 = base64.encode(secretBox.cipherText);

    return '$nonceB64:$macB64:$cipherTextB64';
  }

  static Future<String> decrypt(
    String encryptedData,
    String secretKeyStr,
  ) async {
    final parts = encryptedData.split(':');
    if (parts.length != 3) {
      throw const FormatException('Invalid encrypted message format');
    }

    final nonce = base64.decode(parts[0]);
    final macBytes = base64.decode(parts[1]);
    final cipherText = base64.decode(parts[2]);

    final secretKey = await _deriveKey(secretKeyStr);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

    final decryptedBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decryptedBytes);
  }
}
