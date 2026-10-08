part of 'socket_service.dart';

extension SocketServiceSendMessage on SocketService {
  void sendMessage(
    String chatId,
    String senderId,
    String senderName,
    String text,
    String messageId, {
    String? replyToId,
    bool isDirect = false,
    String? type,
    String? mediaUrl,
    Map<String, dynamic>? mediaMeta,
  }) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('Cannot send message: socket not connected');
      return;
    }

    final payload = {
      'chatId': chatId,
      'clientMessageId': messageId,
      'type': type ?? 'text',
      'content': text,
      'isDirect': isDirect,
      'senderName': senderName,
      if (replyToId != null) 'replyToId': replyToId,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaMeta != null) 'mediaMeta': mediaMeta,
    };

    _socket!.emit('send_chat_message', payload);
  }
}
