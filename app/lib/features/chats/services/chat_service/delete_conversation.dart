part of 'chat_service.dart';

extension ChatServiceDeleteConversation on ChatService {
  /// Owner only — 403 otherwise. Ends the group for every member, unlike
  /// [leaveConversation].
  Future<void> deleteConversation(String chatId) async {
    final response = await HttpService.delete(
      ApiEndpoints.conversation(chatId),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete group');
    }
  }
}
