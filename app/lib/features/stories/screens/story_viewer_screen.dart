import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/utils/deep_link_urls.dart';
import '../../../core/utils/titlecase_function.dart';
import '../../../core/services/media_cache_service.dart';
import '../../../models/story_group_model.dart';
import '../../../models/story_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/story_provider.dart';

class StoryViewerScreen extends StatefulWidget {
  final StoryGroupModel group;

  const StoryViewerScreen({super.key, required this.group});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _imageDuration = Duration(seconds: 5);

  late final List<StoryModel> _stories;
  late int _currentIndex;
  late final AnimationController _progressController;

  VideoPlayerController? _videoController;
  bool _isLoadingVideo = false;
  String? _videoError;
  bool _hasFinished = false;

  StoryModel get _current => _stories[_currentIndex];
  bool get _isVideo => _current.type == 'video';

  @override
  void initState() {
    super.initState();
    // Backend returns newest-first; a status should play oldest-to-newest.
    _stories = List<StoryModel>.from(widget.group.stories)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final firstUnviewed = _stories.indexWhere((s) => !s.isViewed);
    _currentIndex = firstUnviewed == -1 ? 0 : firstUnviewed;

    _progressController =
        AnimationController(
            vsync: this,
            animationBehavior: AnimationBehavior.preserve,
          )
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _goNext();
          });
    _loadCurrent();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadCurrent() {
    _progressController.stop();
    _progressController.reset();
    _videoController?.dispose();
    _videoController = null;
    _videoError = null;

    context.read<StoryProvider>().viewStory(_current.id);

    if (_isVideo) {
      _loadVideo();
    } else {
      _progressController.duration = _imageDuration;
      _progressController.forward(from: 0);
    }
  }

  Future<void> _loadVideo() async {
    setState(() => _isLoadingVideo = true);
    try {
      final story = _current;
      final file = await MediaCacheService().getCachedFile(
        story.mediaUrl,
        fileName: 'story_${story.id}.mp4',
      );
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (!mounted || story.id != _current.id) {
        controller.dispose();
        return;
      }
      controller.addListener(_onVideoTick);
      controller.play();
      setState(() {
        _videoController = controller;
        _isLoadingVideo = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = AppLocalizations.of(
            context,
          ).storyViewerScreenVideoLoadError;
          _isLoadingVideo = false;
        });
      }
    }
  }

  void _onVideoTick() {
    if (!mounted) return;
    final controller = _videoController;
    if (controller == null) return;
    setState(() {});
    final duration = controller.value.duration;
    if (duration > Duration.zero &&
        !controller.value.isPlaying &&
        controller.value.position >= duration) {
      _goNext();
    }
  }

  double get _currentProgress {
    if (_isVideo) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) return 0;
      final total = controller.value.duration.inMilliseconds;
      if (total <= 0) return 0;
      return (controller.value.position.inMilliseconds / total).clamp(0.0, 1.0);
    }
    return _progressController.value;
  }

  void _goNext() {
    if (_currentIndex >= _stories.length - 1) {
      if (_hasFinished) return;
      _hasFinished = true;
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _currentIndex += 1);
    _loadCurrent();
  }

  void _goPrev() {
    if (_currentIndex <= 0) return;
    setState(() => _currentIndex -= 1);
    _loadCurrent();
  }

  bool get _isMine {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    return myId.isNotEmpty && _current.userId == myId;
  }

  Future<void> _deleteCurrentStory() async {
    final l10n = AppLocalizations.of(context);
    final story = _current;
    _pause();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storyViewerScreenDeleteStory),
        content: Text(l10n.storyViewerScreenDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.storyViewerScreenDeleteStory),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) {
      _resume();
      return;
    }

    final deleted = await context.read<StoryProvider>().deleteStory(story.id);
    if (!mounted) return;

    if (!deleted) {
      _showSnack(l10n.storyViewerScreenDeleteFailed);
      _resume();
      return;
    }

    _showSnack(l10n.storyViewerScreenDeleted);
    _stories.removeWhere((s) => s.id == story.id);
    // Nothing left of this person's status to show.
    if (_stories.isEmpty) {
      if (!_hasFinished) {
        _hasFinished = true;
        Navigator.pop(context);
      }
      return;
    }
    // Deleting the last one steps back rather than off the end.
    setState(() {
      if (_currentIndex >= _stories.length) _currentIndex = _stories.length - 1;
    });
    _loadCurrent();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _pause() {
    _progressController.stop();
    _videoController?.pause();
  }

  void _resume() {
    if (_isVideo) {
      _videoController?.play();
    } else {
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final story = _current;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final isLeft =
                    details.localPosition.dx <
                    MediaQuery.of(context).size.width / 2;
                isLeft ? _goPrev() : _goNext();
              },
              onLongPressStart: (_) => _pause(),
              onLongPressEnd: (_) => _resume(),
              child: Center(child: _buildMedia(story)),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  for (var i = 0; i < _stories.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: i < _currentIndex
                              ? 1.0
                              : (i == _currentIndex ? _currentProgress : 0.0),
                          minHeight: 2.5,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _buildAuthorAvatar(group.user),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      toTitleCase(group.user.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (_isMine)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                      ),
                      tooltip: AppLocalizations.of(
                        context,
                      ).storyViewerScreenDeleteStory,
                      onPressed: _deleteCurrentStory,
                    ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () {
                      _pause();
                      SharePlus.instance
                          .share(
                            ShareParams(
                              text:
                                  '${toTitleCase(group.user.name)} on Talkmos: '
                                  '${DeepLinkUrls.story(story.id)}',
                            ),
                          )
                          .whenComplete(_resume);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if ((story.caption ?? '').isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      story.caption!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The author's photo. It was never rendered — the avatar only ever drew
  /// the initial, whether or not the user had one.
  Widget _buildAuthorAvatar(UserModel user) {
    final avatarUrl = user.avatarUrl ?? '';
    return AvatarCircle(
      imageUrl: avatarUrl,
      radius: 18,
      backgroundColor: Colors.white24,
      fallback: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMedia(StoryModel story) {
    if (_isVideo) return _buildVideo();
    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      cacheManager: MediaCacheService.manager,
      fit: BoxFit.contain,
      width: double.infinity,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (_isLoadingVideo) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    if (_videoError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(_videoError!, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadVideo,
            child: Text(AppLocalizations.of(context).commonRetry),
          ),
        ],
      );
    }
    final controller = _videoController;
    if (controller == null) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}
