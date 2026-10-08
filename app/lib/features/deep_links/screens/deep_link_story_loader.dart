import 'package:flutter/material.dart';
import '../../../models/story_group_model.dart';
import '../../../models/user_model.dart';
import '../../stories/screens/story_viewer_screen.dart';
import '../../stories/services/story_service.dart';
import 'deep_link_auth_guard.dart';
import 'deep_link_error_view.dart';

class DeepLinkStoryLoader extends StatefulWidget {
  final String storyId;

  const DeepLinkStoryLoader({super.key, required this.storyId});

  @override
  State<DeepLinkStoryLoader> createState() => _DeepLinkStoryLoaderState();
}

class _DeepLinkStoryLoaderState extends State<DeepLinkStoryLoader> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (redirectIfSignedOut(context)) return;
    try {
      final story = await StoryService().getStoryById(widget.storyId);
      final user = story.userDetails ?? UserModel(id: story.userId, name: '');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewerScreen(
            group: StoryGroupModel(user: user, stories: [story]),
          ),
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
