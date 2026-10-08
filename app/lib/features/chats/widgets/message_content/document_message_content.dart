import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../../models/chat_message_model.dart';
import '../../../../core/services/media_cache_service.dart';
import '../../../../core/services/pdf_preview_service.dart';
import '../../../../core/utils/file_type_display.dart';
import '../../../../core/utils/format_bytes.dart';

class DocumentMessageContent extends StatefulWidget {
  final ChatMessageModel message;
  final Color textColor;

  /// Rides at the end of the type-and-size line — the bubble's timestamp and
  /// tick, kept out of a row of their own.
  final Widget? trailing;

  const DocumentMessageContent({
    super.key,
    required this.message,
    required this.textColor,
    this.trailing,
  });

  @override
  State<DocumentMessageContent> createState() => _DocumentMessageContentState();
}

class _DocumentMessageContentState extends State<DocumentMessageContent> {
  static const double _cardWidth = 250;

  bool _isOpening = false;
  Uint8List? _thumbnail;
  int? _pageCount;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  String get _rawFileName => widget.message.media.fileName;

  String _fileName(BuildContext context) => _rawFileName.isNotEmpty
      ? _rawFileName
      : AppLocalizations.of(context).documentMessageDefaultName;

  bool get _isPdf => PdfPreviewService.isPdf(
    fileName: _rawFileName,
    mimeType: widget.message.media.mimeType,
  );

  /// Renders the first page only for a document already on disk. A thumbnail
  /// is not worth spending someone's data on before they have asked for the
  /// file itself.
  Future<void> _loadThumbnail() async {
    final url = widget.message.media.url;
    if (!_isPdf || url.isEmpty) return;

    try {
      final cache = MediaCacheService();
      if (!await cache.isFileCached(url, fileName: _rawFileName)) return;

      final file = await cache.getCachedFile(url, fileName: _rawFileName);
      final preview = await PdfPreviewService().fromFile(file, cacheKey: url);
      if (!mounted || preview == null) return;

      setState(() {
        _thumbnail = preview.image;
        _pageCount = preview.pageCount;
      });
    } catch (_) {
      // A missing thumbnail is a cosmetic loss; the card still opens the file.
    }
  }

  Future<void> _open() async {
    final url = widget.message.media.url;
    if (url.isEmpty || _isOpening) return;
    setState(() => _isOpening = true);

    final l10n = AppLocalizations.of(context);
    try {
      final file = await MediaCacheService().getCachedFile(
        url,
        fileName: _fileName(context),
      );
      final result = await OpenFilex.open(file.path);
      if (mounted && result.type != ResultType.done) {
        _snack(l10n.documentMessageOpenFailed(result.message));
      }
      // Now that it is on disk, the thumbnail costs nothing.
      if (_thumbnail == null) _loadThumbnail();
    } catch (e) {
      if (mounted) _snack(l10n.documentMessageDownloadFailed);
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  /// "3 pages · PDF · 245 kB" — whichever of those three are known.
  String _subtitle(BuildContext context) {
    final type = fileTypeDisplayFor(
      fileName: _rawFileName,
      mimeType: widget.message.media.mimeType,
    );
    final parts = <String>[];

    final pages = _pageCount;
    if (pages != null && pages > 0) {
      parts.add(
        pages == 1
            ? AppLocalizations.of(context).documentMessagePageCountOne
            : AppLocalizations.of(context).documentMessagePageCount(pages),
      );
    }
    parts.add(type.label);
    if (widget.message.media.size > 0) {
      parts.add(formatBytes(widget.message.media.size));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = fileTypeDisplayFor(
      fileName: _rawFileName,
      mimeType: widget.message.media.mimeType,
    );

    return GestureDetector(
      onTap: _open,
      child: Container(
        width: _cardWidth,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_thumbnail != null) _PageThumbnail(bytes: _thumbnail!),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _TypeBadge(type: type, isLoading: _isOpening, isDark: isDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fileName(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: widget.textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            // The time belongs at the card's right edge, not
                            // trailing the size like another field of it.
                            Expanded(
                              child: Text(
                                _subtitle(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: widget.textColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.trailing != null) ...[
                              const SizedBox(width: 8),
                              widget.trailing!,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rendered first page, cropped to a letterbox so a tall document does not
/// take over the whole conversation.
class _PageThumbnail extends StatelessWidget {
  final Uint8List bytes;

  const _PageThumbnail({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final FileTypeDisplay type;
  final bool isLoading;
  final bool isDark;

  const _TypeBadge({
    required this.type,
    required this.isLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // The brand colours are picked for white; on a dark bubble they are lifted
    // so the icon does not sink into the card.
    final tint = isDark
        ? Color.lerp(type.color, Colors.white, 0.3)!
        : type.color;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: tint),
              )
            : Icon(type.icon, size: 21, color: tint),
      ),
    );
  }
}
