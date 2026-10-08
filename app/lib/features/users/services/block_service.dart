import 'dart:convert';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/http_service.dart';

class BlockService {
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final res = await HttpService.get(ApiEndpoints.blockedUsers);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    throw body['message'] ?? 'Failed to fetch blocked contacts';
  }

  Future<void> blockUser(String userId) async {
    final res = await HttpService.post(ApiEndpoints.blockUser(userId));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['success'] != true) {
      throw body['message'] ?? 'Failed to block contact';
    }
  }

  Future<void> unblockUser(String userId) async {
    final res = await HttpService.post(ApiEndpoints.unblockUser(userId));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['success'] != true) {
      throw body['message'] ?? 'Failed to unblock contact';
    }
  }
}
