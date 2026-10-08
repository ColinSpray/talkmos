import 'dart:convert';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/http_service.dart';

class FriendService {
  Future<void> sendFriendRequest(String receiverId) async {
    final res = await HttpService.post(
      ApiEndpoints.friendRequests,
      body: {'receiverId': receiverId},
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw body['message'] ?? 'Failed to send friend request';
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getPendingRequests() async {
    final res = await HttpService.get(ApiEndpoints.pendingFriendRequests);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      final incoming = (body['incoming'] ?? body['data'] ?? []) as List;
      final outgoing = (body['outgoing'] ?? []) as List;
      return {
        'incoming': List<Map<String, dynamic>>.from(incoming),
        'outgoing': List<Map<String, dynamic>>.from(outgoing),
      };
    }
    throw body['message'] ?? 'Failed to fetch pending requests';
  }

  Future<void> updateFriendRequest(String requestId, String status) async {
    final res = await HttpService.put(
      ApiEndpoints.friendRequest(requestId),
      body: {'status': status},
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw body['message'] ?? 'Failed to update friend request';
    }
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    final res = await HttpService.get(ApiEndpoints.friends);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    throw body['message'] ?? 'Failed to fetch friends list';
  }
}
