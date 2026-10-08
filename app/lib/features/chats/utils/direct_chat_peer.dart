import '../../../models/recent_chat.dart';

String? directChatPeerId(RecentChat chat, String? myId) {
  if (chat.chatType != 'direct' || myId == null || myId.isEmpty) return null;

  final peer = chat.peerFor(myId);
  if (peer != null && peer.id.isNotEmpty) return peer.id;

  final senderId = chat.lastMessageSenderId;
  if (senderId != null && senderId.isNotEmpty && senderId != myId) {
    return senderId;
  }
  return null;
}
