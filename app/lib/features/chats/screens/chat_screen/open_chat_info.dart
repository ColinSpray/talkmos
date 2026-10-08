part of 'chat_screen.dart';

extension _OpenChatInfo on _ChatScreenState {
  void _openChatInfo() {
    if (widget.chatType == 'direct') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UserProfileScreen(user: widget.activeUser, chatId: widget.chatId),
        ),
      );
    } else if (widget.chatType == 'community') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(
            chatId: widget.chatId,
            fallbackName: widget.activeUser.name,
            fallbackImageUrl: widget.activeUser.avatarUrl,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupProfileScreen(
            chatId: widget.chatId,
            groupName: widget.activeUser.name,
            groupAvatarUrl: widget.activeUser.avatarUrl,
          ),
        ),
      );
    }
  }
}
