import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../../models/chat_message_model.dart';
import '../../../../core/services/media_cache_service.dart';
import '../../screens/full_screen_image_viewer.dart';

class ImageMessageContent extends StatelessWidget {
  final ChatMessageModel message;
  final Color textColor;
  final Uint8List? localBytes;

  const ImageMessageContent({
    super.key,
    required this.message,
    required this.textColor,
    this.localBytes,
  });

  @override
  Widget build(BuildContext context) {
    final url = message.media.url;
    if (url.isEmpty && localBytes == null) {
      return Text(
        message.content,
        style: TextStyle(fontSize: 15, color: textColor),
      );
    }

    final isUploading =
        message.status == MessageStatus.sending && localBytes != null;
    final heroTag = 'image_${message.id}_${url.hashCode}';

    Widget imageWidget;
    if (localBytes != null) {
      imageWidget = Image.memory(
        localBytes!,
        width: 220,
        height: 160,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        cacheManager: MediaCacheService.manager,
        width: 220,
        height: 160,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 220,
          height: 160,
          color: Colors.grey.withValues(alpha: 0.15),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.indigo,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 220,
          height: 160,
          color: Colors.red.withValues(alpha: 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).imageMessageFailedToLoad,
                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: url.isEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FullScreenImageViewer(imageUrl: url, heroTag: heroTag),
                ),
              );
            },
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              imageWidget,
              if (isUploading)
                Container(
                  width: 220,
                  height: 160,
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
