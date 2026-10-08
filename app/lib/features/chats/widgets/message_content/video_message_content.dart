import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../../models/chat_message_model.dart';
import '../../../../core/services/media_cache_service.dart';
import '../../screens/video_player_screen.dart';

/// A video message's thumbnail card. Tapping plays it full-screen.
class VideoMessageContent extends StatelessWidget {
  final ChatMessageModel message;
  final Uint8List? localBytes;

  /// A locally-generated preview frame, shown while the real thumbnail is
  /// still uploading so the bubble doesn't sit on a blank placeholder.
  final Uint8List? localThumbnailBytes;

  const VideoMessageContent({
    super.key,
    required this.message,
    this.localBytes,
    this.localThumbnailBytes,
  });

  @override
  Widget build(BuildContext context) {
    final url = message.media.url;
    final isUploading =
        message.status == MessageStatus.sending && localBytes != null;
    final heroTag = 'video_${message.id}_${url.hashCode}';

    return GestureDetector(
      onTap: url.isEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    videoUrl: url,
                    heroTag: heroTag,
                    fileName: message.media.fileName,
                  ),
                ),
              );
            },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 220,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (message.media.thumbnail.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: message.media.thumbnail,
                    cacheManager: MediaCacheService.manager,
                    width: 220,
                    height: 160,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _videoPlaceholder(),
                  )
                else if (localThumbnailBytes != null)
                  Image.memory(
                    localThumbnailBytes!,
                    width: 220,
                    height: 160,
                    fit: BoxFit.cover,
                  )
                else
                  _videoPlaceholder(),

                Container(color: Colors.black.withValues(alpha: 0.35)),

                if (isUploading)
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                Positioned(
                  left: 8,
                  bottom: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.videocam_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).commonVideo.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (message.media.size > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatFileSize(message.media.size),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000814), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
