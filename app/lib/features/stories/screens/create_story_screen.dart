import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/story_provider.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/file_naming_service.dart';
import '../../../core/utils/image_edit_utils.dart';
import '../../../core/widgets/add_text_label_dialog.dart';
import '../../../core/widgets/emoji_picker_sheet.dart';
import '../utils/story_compositor.dart';
import '../widgets/story_editor_models.dart';
import '../widgets/story_overlay_layer.dart';

const _videoExtensions = [
  '.mp4',
  '.mov',
  '.mkv',
  '.webm',
  '.3gp',
  '.avi',
  '.m4v',
];

bool _looksLikeVideo(XFile file) {
  final mimeType = file.mimeType;
  if (mimeType != null) return mimeType.startsWith('video/');
  final lower = file.name.toLowerCase();
  return _videoExtensions.any(lower.endsWith);
}

class _PickedMedia {
  final XFile file;
  Uint8List bytes;
  final bool isVideo;

  /// Null only for video items, which don't use the image editor.
  Size? naturalSize;

  final TextEditingController captionController = TextEditingController();
  int rotationQuarterTurns = 0;
  int filterIndex = 0;
  final List<StoryTextItem> textItems = [];
  final List<StoryStickerItem> stickerItems = [];

  _PickedMedia({
    required this.file,
    required this.bytes,
    required this.isVideo,
    this.naturalSize,
  });

  bool get hasEdits =>
      rotationQuarterTurns != 0 ||
      filterIndex != 0 ||
      textItems.isNotEmpty ||
      stickerItems.isNotEmpty;

  void dispose() => captionController.dispose();
}

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _picker = ImagePicker();
  final _pageController = PageController();

  final List<_PickedMedia> _items = [];
  int _currentIndex = 0;
  String _selectedCategory = 'Friends';
  bool _isSharing = false;
  bool _showFilterStrip = false;

  static const _categories = ['Friends', 'Travel', 'Food', 'Lifestyle'];

  _PickedMedia get _currentItem => _items[_currentIndex];

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addItem(XFile file, {required bool isVideo}) async {
    final bytes = await file.readAsBytes();
    final naturalSize = isVideo ? null : await decodeImageSize(bytes);
    if (!mounted) return;
    setState(() {
      _items.add(
        _PickedMedia(
          file: file,
          bytes: bytes,
          isVideo: isVideo,
          naturalSize: naturalSize,
        ),
      );
      _currentIndex = _items.length - 1;
      _showFilterStrip = false;
    });
    // Jump once the page has actually been laid out with the new item.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    await _addItem(file, isVideo: false);
  }

  Future<void> _pickVideo(ImageSource source) async {
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 90),
    );
    if (file == null) return;
    await _addItem(file, isVideo: true);
  }

  /// Gallery multi-select — photos and videos mixed together in one pick,
  /// each appended as its own story.
  Future<void> _pickFromGallery() async {
    final files = await _picker.pickMultipleMedia(imageQuality: 85);
    for (final file in files) {
      await _addItem(file, isVideo: _looksLikeVideo(file));
    }
  }

  void _removeAt(int index) {
    setState(() {
      _items.removeAt(index).dispose();
      if (_items.isEmpty) return;
      // Keep pointing at the same visual item when something earlier shifts down.
      if (index < _currentIndex) _currentIndex -= 1;
      _currentIndex = _currentIndex.clamp(0, _items.length - 1);
      _showFilterStrip = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && _items.isNotEmpty) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  // ─── Per-item editing ───────────────────────────────────────────────────

  Future<void> _cropCurrentItem() async {
    final item = _currentItem;
    final title = AppLocalizations.of(
      context,
    ).mediaPreviewScreenCropImageTooltip;
    final bytes = await cropImageBytes(context, item.bytes, title: title);
    if (bytes == null || !mounted) return;

    final naturalSize = await decodeImageSize(bytes);
    if (!mounted) return;
    setState(() {
      item.bytes = bytes;
      item.naturalSize = naturalSize;
    });
  }

  void _rotateCurrentItem() {
    setState(() {
      _currentItem.rotationQuarterTurns = nextQuarterTurn(
        _currentItem.rotationQuarterTurns,
      );
    });
  }

  Future<void> _addTextToCurrentItem() async {
    final text = await showAddTextLabelDialog(context);
    if (text == null) return;
    setState(() {
      _currentItem.textItems.add(
        StoryTextItem(
          text: text,
          position: const Offset(0.5, 0.5),
          color: Colors.white,
        ),
      );
    });
  }

  void _addStickerToCurrentItem() {
    showEmojiPickerSheet(
      context,
      onEmojiSelected: (_, emoji) {
        setState(() {
          _currentItem.stickerItems.add(
            StoryStickerItem(
              emoji: emoji.emoji,
              position: const Offset(0.5, 0.5),
            ),
          );
        });
      },
    );
  }

  void _toggleFilterStrip() {
    setState(() => _showFilterStrip = !_showFilterStrip);
  }

  void _selectFilter(int index) {
    setState(() => _currentItem.filterIndex = index);
  }

  Future<void> _share() async {
    if (_items.isEmpty || _isSharing) return;
    setState(() => _isSharing = true);

    final uploadItems = <StoryUploadItem>[];
    for (final item in _items) {
      var bytes = item.bytes;
      var mimeType =
          item.file.mimeType ?? (item.isVideo ? 'video/mp4' : 'image/jpeg');
      if (!item.isVideo && item.hasEdits) {
        bytes = await compositeStoryImage(
          bytes: item.bytes,
          rotationQuarterTurns: item.rotationQuarterTurns,
          colorFilter: kStoryFilters[item.filterIndex].colorFilter,
          textItems: item.textItems,
          stickerItems: item.stickerItems,
        );
        mimeType = 'image/png';
      }
      uploadItems.add(
        StoryUploadItem(
          bytes: bytes,
          fileName: FileNamingService.getUploadName(item.file.name, mimeType),
          mimeType: mimeType,
          mediaType: item.isVideo ? 'video' : 'image',
          caption: item.captionController.text.trim(),
        ),
      );
    }

    if (!mounted) return;

    context.read<StoryProvider>().uploadAndCreateStories(
      uploadItems,
      category: _selectedCategory,
    );
    AnalyticsService.logEvent(
      'story_posted',
      parameters: {'item_count': uploadItems.length},
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMedia = _items.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F17) : Colors.white,
      appBar: AppBar(
        backgroundColor: hasMedia ? Colors.black : null,
        foregroundColor: hasMedia ? Colors.white : null,
        elevation: 0,
        title: Text(
          hasMedia
              ? l10n.createStoryScreenTitleWithCount(_items.length)
              : l10n.createStoryScreenTitle,
        ),
        actions: [
          if (hasMedia) ...[
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: l10n.createStoryScreenAddMoreTooltip,
              onPressed: _showAddMoreSheet,
            ),
            TextButton(
              onPressed: _isSharing ? null : _share,
              child: Text(
                l10n.createStoryScreenShare,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ],
      ),
      body: hasMedia
          ? _buildComposer(isDark, theme)
          : _buildPicker(isDark, theme),
    );
  }

  Widget _buildPicker(bool isDark, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    Widget option(IconData icon, String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 104,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000814) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: theme.primaryColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.createStoryScreenPickerTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createStoryScreenPickerSubtitle,
            style: TextStyle(
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              option(
                Icons.photo_library_rounded,
                l10n.commonGallery,
                _pickFromGallery,
              ),
              const SizedBox(width: 12),
              option(
                Icons.camera_alt_rounded,
                l10n.createStoryScreenPhotoOption,
                () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 12),
              option(
                Icons.videocam_rounded,
                l10n.commonVideo,
                () => _pickVideo(ImageSource.camera),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMoreSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF000814)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.commonGallery),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: Text(l10n.createStoryScreenCameraPhoto),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_rounded),
                title: Text(l10n.createStoryScreenCameraVideo),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickVideo(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(bool isDark, ThemeData theme) {
    final canEdit = !_currentItem.isVideo;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (i) => setState(() {
                  _currentIndex = i;
                  _showFilterStrip = false;
                }),
                itemBuilder: (_, i) => Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: _StoryMediaPreview(item: _items[i]),
                ),
              ),
              if (canEdit)
                Positioned(right: 16, top: 16, child: _buildEditToolbar(theme)),
              if (canEdit && _showFilterStrip)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: _buildFilterStrip(theme),
                ),
            ],
          ),
        ),
        if (_items.length > 1) _buildThumbnailStrip(theme),
        // Fixed dark for the same reason as the thumbnail strip above — it
        // borders the black canvas, so it stays dark regardless of app theme.
        Container(
          color: const Color(0xFF000000),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final cat in _categories) ...[
                      ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    // Keyed by index so switching pages swaps in that
                    // item's own caption controller instead of reusing state.
                    child: TextField(
                      key: ValueKey(_currentIndex),
                      controller: _items[_currentIndex].captionController,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF000000),
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        ).createStoryScreenCaptionHint,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF000814)
                            : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isSharing ? null : _share,
                    child: Opacity(
                      opacity: _isSharing ? 0.5 : 1.0,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.primaryColor,
                        child: _isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditToolbar(ThemeData theme) {
    Widget button(IconData icon, VoidCallback onTap, {bool active = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active
                  ? theme.primaryColor
                  : Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: active ? 0 : 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Tooltip(
          message: l10n.mediaPreviewScreenCropImageTooltip,
          child: button(Icons.crop_rounded, _cropCurrentItem),
        ),
        Tooltip(
          message: l10n.mediaPreviewScreenRotateImageTooltip,
          child: button(Icons.rotate_right_rounded, _rotateCurrentItem),
        ),
        Tooltip(
          message: l10n.mediaPreviewScreenAddTextTooltip,
          child: button(Icons.title_rounded, _addTextToCurrentItem),
        ),
        Tooltip(
          message: l10n.createStoryScreenAddStickerTooltip,
          child: button(
            Icons.emoji_emotions_outlined,
            _addStickerToCurrentItem,
          ),
        ),
        Tooltip(
          message: l10n.createStoryScreenFilterTooltip,
          child: button(
            Icons.tune_rounded,
            _toggleFilterStrip,
            active: _showFilterStrip,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterStrip(ThemeData theme) {
    final item = _currentItem;
    return Container(
      height: 100,
      color: Colors.black45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: kStoryFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final filter = kStoryFilters[i];
          final selected = item.filterIndex == i;
          Widget thumb = Image.memory(
            item.bytes,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          );
          if (filter.colorFilter != null) {
            thumb = ColorFiltered(
              colorFilter: filter.colorFilter!,
              child: thumb,
            );
          }
          return GestureDetector(
            onTap: () => _selectFilter(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? theme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(child: thumb),
                ),
                const SizedBox(height: 4),
                Text(
                  filter.name,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnailStrip(ThemeData theme) {
    return Container(
      height: 72,
      color: const Color(0xFF0B0F17),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = _items[i];
          final selected = i == _currentIndex;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? theme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.isVideo
                      ? Container(
                          color: const Color(0xFF000814),
                          child: const Icon(
                            Icons.videocam_rounded,
                            color: Colors.white70,
                          ),
                        )
                      : Image.memory(item.bytes, fit: BoxFit.cover),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => _removeAt(i),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoryMediaPreview extends StatefulWidget {
  final _PickedMedia item;

  const _StoryMediaPreview({required this.item});

  @override
  State<_StoryMediaPreview> createState() => _StoryMediaPreviewState();
}

class _StoryMediaPreviewState extends State<_StoryMediaPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.file(File(widget.item.file.path));
    await controller.initialize();
    if (!mounted) {
      controller.dispose();
      return;
    }
    controller
      ..setLooping(true)
      ..play();
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.isVideo) {
      final naturalSize = widget.item.naturalSize;
      if (naturalSize == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      Widget image = Image.memory(widget.item.bytes, fit: BoxFit.contain);
      final filter = kStoryFilters[widget.item.filterIndex].colorFilter;
      if (filter != null) {
        image = ColorFiltered(colorFilter: filter, child: image);
      }

      final rotated = widget.item.rotationQuarterTurns.isOdd;
      final ratio = rotated
          ? naturalSize.height / naturalSize.width
          : naturalSize.width / naturalSize.height;

      return Center(
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RotatedBox(
                quarterTurns: widget.item.rotationQuarterTurns,
                child: image,
              ),
              StoryOverlayLayer(
                textItems: widget.item.textItems,
                stickerItems: widget.item.stickerItems,
                onChanged: () => setState(() {}),
                onTextRemoved: (i) =>
                    setState(() => widget.item.textItems.removeAt(i)),
                onStickerRemoved: (i) =>
                    setState(() => widget.item.stickerItems.removeAt(i)),
              ),
            ],
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: () => setState(() {
        controller.value.isPlaying ? controller.pause() : controller.play();
      }),
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              if (!controller.value.isPlaying)
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white70,
                  size: 56,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
