import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/shared_media_item.dart';
import '../../../core/services/media_cache_service.dart';
import '../services/chat_service/chat_service.dart';
import 'full_screen_image_viewer.dart';
import 'video_player_screen.dart';

/// Grid gallery of every image/video shared in a chat, newest first.
class SharedMediaScreen extends StatefulWidget {
  final String chatId;
  final String title;

  const SharedMediaScreen({
    super.key,
    required this.chatId,
    required this.title,
  });

  @override
  State<SharedMediaScreen> createState() => _SharedMediaScreenState();
}

class _SharedMediaScreenState extends State<SharedMediaScreen> {
  final _chatService = ChatService();
  final _scrollController = ScrollController();

  final List<SharedMediaItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _chatService.getSharedMedia(widget.chatId);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _hasMore = page.items.length >= 30;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).sharedMediaScreenLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final page = await _chatService.getSharedMedia(
        widget.chatId,
        before: _items.last.createdAt,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _hasMore = page.items.length >= 30;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).sharedMediaScreenTitle,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _error != null
          ? _buildError(textColor, subtextColor)
          : _items.isEmpty
          ? _buildEmpty(textColor, subtextColor)
          : RefreshIndicator(
              onRefresh: _load,
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: _items.length + (_isLoadingMore ? 3 : 0),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return Container(
                      color: subtextColor.withValues(alpha: 0.08),
                    );
                  }
                  return _MediaTile(item: _items[index]);
                },
              ),
            ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 21,
        itemBuilder: (_, __) => Container(color: Colors.grey),
      ),
    );
  }

  Widget _buildEmpty(Color textColor, Color subtextColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 56,
            color: subtextColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).sharedMediaScreenEmptyTitle,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).sharedMediaScreenEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: subtextColor, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color textColor, Color subtextColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: subtextColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: textColor, fontSize: 15)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _load,
            child: Text(AppLocalizations.of(context).commonRetry),
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final SharedMediaItem item;

  const _MediaTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.messageType == MessageType.video;
    final thumbnailUrl = isVideo && item.media.thumbnail.isNotEmpty
        ? item.media.thumbnail
        : item.media.url;
    final heroTag = 'shared_media_${item.id}';

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                videoUrl: item.media.url,
                heroTag: heroTag,
                fileName: item.media.fileName,
              ),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageUrl: item.media.url,
              heroTag: heroTag,
            ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: thumbnailUrl,
              cacheManager: MediaCacheService.manager,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: Colors.grey.withValues(alpha: 0.15)),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.grey,
                ),
              ),
            ),
            if (isVideo)
              Container(
                color: Colors.black.withValues(alpha: 0.15),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
