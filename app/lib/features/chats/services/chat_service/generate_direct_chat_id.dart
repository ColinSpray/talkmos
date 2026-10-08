part of 'chat_service.dart';

extension ChatServiceGenerateDirectChatId on ChatService {
  /// Creates or fetches a direct chat and returns its chatId (compatibility
  /// wrapper around [createConversation]).
  Future<String> generateDirectChatId(String peerId) async {
    final chat = await createConversation(
      type: 'direct',
      participantIds: [peerId],
    );
    return chat['_id'] as String;
  }
}
