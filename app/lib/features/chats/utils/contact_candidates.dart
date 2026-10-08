import '../../../models/friend_model.dart';
import '../../../models/recent_chat.dart';
import 'direct_chat_peer.dart';

List<FriendModel> contactCandidates({
  required List<FriendModel> friends,
  required List<RecentChat> chats,
  required String? myId,
  Set<String> exclude = const {},
}) {
  final byId = <String, FriendModel>{
    for (final f in friends)
      if (f.id.isNotEmpty && !exclude.contains(f.id)) f.id: f,
  };

  for (final chat in chats) {
    final peerId = directChatPeerId(chat, myId);
    if (peerId == null ||
        byId.containsKey(peerId) ||
        exclude.contains(peerId)) {
      continue;
    }
    final peer = chat.peerFor(myId);
    // A direct chat's name/image are the other participant's, which is what
    // to fall back on when the member entry itself is missing.
    byId[peerId] = FriendModel(
      id: peerId,
      name: peer?.name.isNotEmpty == true ? peer!.name : chat.name,
      avatarUrl: chat.avatarUrl,
      chatId: chat.id,
    );
  }

  return byId.values.toList();
}
