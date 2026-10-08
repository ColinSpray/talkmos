import 'encryption_helper.dart';

const int cryptoIsolateThreshold = 8;

Future<Map<String, String>> decryptBatch(
  List<Map<String, String>> items,
) async {
  final result = <String, String>{};
  for (final item in items) {
    final id = item['id']!;
    final content = item['content']!;
    final key = item['key']!;
    try {
      result[id] = await EncryptionHelper.decrypt(content, key);
    } catch (_) {
      result[id] = content;
    }
  }
  return result;
}

/// Same shape as [decryptBatch], for encryption.
Future<Map<String, String>> encryptBatch(
  List<Map<String, String>> items,
) async {
  final result = <String, String>{};
  for (final item in items) {
    result[item['id']!] = await EncryptionHelper.encrypt(
      item['content']!,
      item['key']!,
    );
  }
  return result;
}
