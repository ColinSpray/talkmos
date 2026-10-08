part of 'chat_service.dart';

extension ChatServiceUpdateGroupPermissions on ChatService {
  /// Admin/owner only — the server rejects anyone else with a 403.
  Future<Map<String, dynamic>> updateGroupPermissions(
    String chatId,
    Map<String, String> permissions,
  ) async {
    final response = await HttpService.patch(
      ApiEndpoints.conversationPermissions(chatId),
      body: {'permissions': permissions},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      return Map<String, dynamic>.from(body['data'] ?? {});
    }
    throw Exception(body['message'] ?? 'Failed to update permissions');
  }
}
