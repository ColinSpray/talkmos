import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../../../../models/nearby_user_model.dart';

part 'set_nearby_enabled.dart';
part 'heartbeat.dart';
part 'ping.dart';
part 'send_nearby_request.dart';

class NearbyService {
  Map<String, dynamic> _parse(http.Response response) {
    final text = response.body.trim();
    if (text.isEmpty || text.startsWith('<')) {
      throw ApiException(
        'Server returned invalid response',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Unexpected response format');
    }
    if (decoded['success'] != true) {
      throw ApiException(
        decoded['message'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
