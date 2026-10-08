import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

class IsolateWorker {
  static Future<T> run<T>(FutureOr<T> Function() computation) {
    return Isolate.run(computation);
  }

  static Future<Map<String, dynamic>> parseJson(String jsonStr) {
    return Isolate.run(() {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('JSON output is not a Map<String, dynamic>');
    });
  }

  static Future<List<dynamic>> parseJsonList(String jsonStr) {
    return Isolate.run(() {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      throw const FormatException('JSON output is not a List<dynamic>');
    });
  }
}
