import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/http_service.dart';

/// The one network call the key service makes, behind a seam so a test can
/// stand in for it without a server.
class KeyHttpClient {
  const KeyHttpClient();

  Future<Map<String, dynamic>?> getJson(Uri uri) async {
    final response = await HttpService.get(uri);
    final text = response.body.trim();
    if (text.isEmpty || text.startsWith('<')) return null;

    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }
}

/// Returns a fixed body and never touches the network.
@visibleForTesting
class FakeKeyHttpClient implements KeyHttpClient {
  final Map<String, dynamic>? body;
  final Object? error;
  int calls = 0;

  FakeKeyHttpClient({this.body, this.error});

  @override
  Future<Map<String, dynamic>?> getJson(Uri uri) async {
    calls++;
    if (error != null) throw error!;
    return body;
  }
}
