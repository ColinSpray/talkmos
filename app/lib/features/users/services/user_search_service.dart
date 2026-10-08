import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/http_service.dart';
import '../../../models/user_model.dart';

class UserSearchService {
  static String get _base => ApiConfig.userSearchUrl;

  Future<List<Map<String, dynamic>>> search(String q) async {
    final uri = Uri.parse('$_base/search').replace(queryParameters: {'q': q});
    final res = await HttpService.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    throw body['message'] ?? 'Search failed';
  }

  /// Public profile lookup — used to resolve a chat deep link (`talkmos://chat/<userId>`)
  /// into a real name/avatar before starting or opening the conversation.
  Future<UserModel> getUserById(String userId) async {
    final res = await HttpService.get(ApiEndpoints.userById(userId));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return UserModel.fromJson(Map<String, dynamic>.from(body['data']));
    }
    throw body['message'] ?? 'User not found';
  }
}
