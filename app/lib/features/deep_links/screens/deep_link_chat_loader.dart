import 'package:flutter/material.dart';
import '../../chats/services/chat_service/chat_service.dart';
import '../../chats/screens/chat_screen/chat_screen.dart';
import '../../users/services/user_search_service.dart';
import 'deep_link_auth_guard.dart';
import 'deep_link_error_view.dart';

class DeepLinkChatLoader extends StatefulWidget {
  final String userId;

  const DeepLinkChatLoader({super.key, required this.userId});

  @override
  State<DeepLinkChatLoader> createState() => _DeepLinkChatLoaderState();
}

class _DeepLinkChatLoaderState extends State<DeepLinkChatLoader> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (redirectIfSignedOut(context)) return;
    try {
      final user = await UserSearchService().getUserById(widget.userId);
      final chatId = await ChatService().generateDirectChatId(user.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(activeUser: user, chatId: chatId, chatType: 'direct'),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return DeepLinkErrorView(message: _error!);
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
