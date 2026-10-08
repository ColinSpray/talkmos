import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/services/pdf_preview_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_type_display.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/utils/image_edit_utils.dart';
import '../../../../core/widgets/add_text_label_dialog.dart';

/// Models for drawing stroke and draggable text labels on the preview screen
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    required this.color,
    this.strokeWidth = 4.0,
  });
}

class TextLabel {
  String text;
  Offset position;
  Color color;

  TextLabel({required this.text, required this.position, required this.color});
}

class _PreviewPalette {
  /// The user's chosen accent.
  final Color accent;

  /// Content drawn on top of [accent].
  final Color onAccent;

  final Color surface;
  final Color text;
  final Color textMuted;

  /// Unselected swatch rings and the slider's inactive track. Deliberately
  /// stronger than `dividerColor`, which is faint enough to disappear.
  final Color border;

  /// Darkening behind content laid over the media itself.
  final Color scrim;

  final Color shadow;

  const _PreviewPalette({
    required this.accent,
    required this.onAccent,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.scrim,
    required this.shadow,
  });

  factory _PreviewPalette.from(ThemeData theme) {
    final scheme = theme.colorScheme;
    final text = theme.textTheme.bodyLarge?.color ?? scheme.onSurface;
    return _PreviewPalette(
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      surface: theme.cardColor,
      text: text,
      textMuted: theme.textTheme.bodyMedium?.color ?? scheme.onSurfaceVariant,
      border: text.withValues(alpha: 0.24),
      scrim: theme.brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.65)
          : Colors.black.withValues(alpha: 0.45),
      shadow: theme.shadowColor,
    );
  }
}

enum PreviewKind { image, video, audio, file }

/// Classifies [mimeType] for preview. Falls back to a file card, so a type
/// nobody anticipated still gets a preview and a caption box.
PreviewKind previewKindFor(String mimeType) {
  final type = mimeType.toLowerCase();
  if (type.startsWith('image/')) return PreviewKind.image;
  if (type.startsWith('video/')) return PreviewKind.video;
  if (type.startsWith('audio/')) return PreviewKind.audio;
  return PreviewKind.file;
}

class MediaPreviewScreen extends StatefulWidget {
  final Uint8List fileBytes;
  final String fileName;
  final String mimeType;
  final int? duration;

  const MediaPreviewScreen({
    super.key,
    required this.fileBytes,
    required this.fileName,
    required this.mimeType,
    this.duration,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen>
    with SingleTickerProviderStateMixin {
  // Video player state (if video)
  VideoPlayerController? _videoController;
  bool _videoFailed = false;

  // Audio Player state (if audio)
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  late AnimationController _pulseController;
  final TextEditingController _captionController = TextEditingController();
  final GlobalKey _boundaryKey = GlobalKey();

  // Interactive Media Features
  Uint8List? _croppedBytes;
  int _rotationQuarterTurns = 0;
  bool _isDrawingMode = false;
  final List<DrawingStroke> _strokes = [];
  DrawingStroke? _currentStroke;
  Color _selectedColor = AppTheme.primary;
  final List<TextLabel> _textLabels = [];

  PreviewKind get _kind => previewKindFor(widget.mimeType);

  bool get _isImage => _kind == PreviewKind.image;
  bool get _isVideo => _kind == PreviewKind.video;
  bool get _isAudio => _kind == PreviewKind.audio;

  Uint8List get _workingBytes => _croppedBytes ?? widget.fileBytes;

  Uint8List? _pdfPage;
  int? _pdfPageCount;
  bool _pdfRenderSettled = false;

  /// Only while a render is still plausible. Once it has settled without an
  /// image there is nothing to page-preview, so the card shows the icon.
  bool get _showsPdfPage => _isPdf && (!_pdfRenderSettled || _pdfPage != null);

  final List<Color> _paletteColors = [
    AppTheme.primary,
    AppTheme.secondary,
    AppTheme.accent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (_isAudio) {
      _initAudioPlayer();
    } else if (_isVideo) {
      _initVideoPlayer();
    } else if (_isPdf) {
      _initPdfPreview();
    }
  }

  bool get _isPdf => PdfPreviewService.isPdf(
    fileName: widget.fileName,
    mimeType: widget.mimeType,
  );

  Future<void> _initPdfPreview() async {
    PdfPreview? preview;
    try {
      preview = await PdfPreviewService().fromBytes(
        widget.fileBytes,
        cacheKey: '${widget.fileName}:${widget.fileBytes.length}',
      );
    } catch (e) {
      debugPrint('[MediaPreview] pdf render failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _pdfPage = preview?.image;
      _pdfPageCount = preview?.pageCount;
      // Recorded either way. A file that cannot be rendered — encrypted,
      // truncated, or not really a PDF — falls back to the icon card instead
      // of leaving a spinner turning over nothing.
      _pdfRenderSettled = true;
    });
  }

  /// video_player needs a file, and a pick only hands us bytes — so stage it
  /// in the temp directory the same way the audio preview does.
  Future<void> _initVideoPlayer() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/preview_video_${widget.fileName.hashCode}.tmp',
      );
      await file.writeAsBytes(widget.fileBytes);

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onVideoTick);
      setState(() => _videoController = controller);
    } catch (e) {
      debugPrint('Error initializing video preview: $e');
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (!mounted || controller == null) return;
    setState(() {
      _isPlaying = controller.value.isPlaying;
      _position = controller.value.position;
      _duration = controller.value.duration;
    });
  }

  Future<void> _toggleVideoPlayback() async {
    final controller = _videoController;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _initAudioPlayer() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/preview_audio_${widget.fileName.hashCode}.tmp',
      );
      await file.writeAsBytes(widget.fileBytes);

      final player = AudioPlayer();
      _audioPlayer = player;

      _playerStateSub = player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state.playing);
          if (state.playing) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
          }
        }
      });

      _positionSub = player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _durationSub = player.durationStream.listen((dur) {
        if (mounted && dur != null) setState(() => _duration = dur);
      });

      await player.setFilePath(file.path);
    } catch (e) {
      debugPrint('Error initializing audio preview: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _captionController.dispose();
    if (_isAudio) {
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _durationSub?.cancel();
      _audioPlayer?.dispose();
    }
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final player = _audioPlayer;
    if (player == null) return;
    try {
      if (_isPlaying) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (e) {
      debugPrint('Error in preview playback: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _cropImage() async {
    final title = AppLocalizations.of(
      context,
    ).mediaPreviewScreenCropImageTooltip;
    final bytes = await cropImageBytes(context, _workingBytes, title: title);
    if (bytes == null || !mounted) return;
    setState(() => _croppedBytes = bytes);
  }

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing edited image: $e');
      return null;
    }
  }

  Future<void> _showAddTextDialog(_PreviewPalette palette) async {
    // The dialog is a route of its own, so it builds outside this screen's
    // Theme and has to be handed the palette explicitly.
    final text = await showAddTextLabelDialog(
      context,
      backgroundColor: palette.surface,
      textColor: palette.text,
      hintColor: palette.textMuted,
      fieldAccentColor: _selectedColor,
      confirmButtonColor: palette.accent,
    );
    if (text == null) return;
    setState(() {
      _textLabels.add(
        TextLabel(
          text: text,
          position: const Offset(100, 200),
          color: _selectedColor,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData base = Theme.of(context);
    final ThemeData theme = base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        // Follows the base theme's background rather than restating it, so the
        // app bar can't drift out of step with the body beneath it.
        backgroundColor: base.scaffoldBackgroundColor,
        elevation: 0,
        // Without this the app bar tints itself as content scrolls under it,
        // breaking the flush join with the media area below.
        scrolledUnderElevation: 0,
      ),
    );
    final palette = _PreviewPalette.from(theme);
    final l10n = AppLocalizations.of(context);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: palette.text),
            onPressed: () => Navigator.pop(context, {'confirmed': false}),
          ),
          actions: [
            if (_isImage) ...[
              // Crop Action
              IconButton(
                icon: Icon(Icons.crop_rounded, color: palette.text),
                tooltip: l10n.mediaPreviewScreenCropImageTooltip,
                onPressed: _cropImage,
              ),
              // Image Rotation Action (Quarter-turn 90deg Clockwise)
              IconButton(
                icon: Icon(Icons.rotate_right_rounded, color: palette.text),
                tooltip: l10n.mediaPreviewScreenRotateImageTooltip,
                onPressed: () {
                  setState(() {
                    _rotationQuarterTurns = nextQuarterTurn(
                      _rotationQuarterTurns,
                    );
                  });
                },
              ),
              // Add Text Label Overlay
              IconButton(
                icon: Icon(Icons.title_rounded, color: palette.text),
                tooltip: l10n.mediaPreviewScreenAddTextTooltip,
                onPressed: () => _showAddTextDialog(palette),
              ),
              // Free-hand Drawing Doodle Mode
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  // Active state uses the user's accent, not a fixed blue.
                  color: _isDrawingMode ? palette.accent : palette.text,
                ),
                tooltip: l10n.mediaPreviewScreenDrawDoodleTooltip,
                onPressed: () {
                  setState(() {
                    _isDrawingMode = !_isDrawingMode;
                  });
                },
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Drawing Toolbar Option Row (Active only when drawing mode is enabled)
            if (_isDrawingMode && _isImage) _buildDrawControlsBar(palette),
            // Immersive Media Preview
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: switch (_kind) {
                    PreviewKind.image => _buildImagePreviewStack(palette),
                    PreviewKind.video => _buildVideoPreviewCard(palette),
                    PreviewKind.audio => _buildAudioPreviewCard(palette),
                    PreviewKind.file => _buildFilePreviewCard(palette),
                  },
                ),
              ),
            ),
            SafeArea(top: false, child: _buildBottomActionBar(palette)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawControlsBar(_PreviewPalette palette) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: palette.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: _paletteColors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: palette.text, width: 2)
                        : Border.all(color: palette.border, width: 1),
                  ),
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.undo_rounded, color: palette.text),
            tooltip: l10n.mediaPreviewScreenUndoStrokeTooltip,
            onPressed: () {
              setState(() {
                if (_strokes.isNotEmpty) _strokes.removeLast();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewStack(_PreviewPalette palette) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          key: _boundaryKey,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotatable Zoomable Image
              InteractiveViewer(
                clipBehavior: Clip.none,
                minScale: 1.0,
                maxScale: 4.0,
                scaleEnabled: !_isDrawingMode,
                panEnabled: !_isDrawingMode,
                child: RotatedBox(
                  quarterTurns: _rotationQuarterTurns,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_workingBytes, fit: BoxFit.contain),
                  ),
                ),
              ),
              // Doodle Drawing Canvas Overlay
              if (_isDrawingMode)
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _currentStroke = DrawingStroke(
                          points: [details.localPosition],
                          color: _selectedColor,
                        );
                        _strokes.add(_currentStroke!);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        if (_currentStroke != null) {
                          _currentStroke!.points.add(details.localPosition);
                        }
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _currentStroke = null;
                      });
                    },
                    child: CustomPaint(
                      painter: StrokePainter(strokes: _strokes),
                      size: Size.infinite,
                    ),
                  ),
                )
              else
                // If not in drawing mode, still display drawing strokes static
                IgnorePointer(
                  child: CustomPaint(
                    painter: StrokePainter(strokes: _strokes),
                    size: Size.infinite,
                  ),
                ),
              // Draggable Text Labels Overlays
              ..._textLabels.map((label) {
                return Positioned(
                  left: label.position.dx.clamp(
                    0.0,
                    constraints.maxWidth - 100,
                  ),
                  top: label.position.dy.clamp(0.0, constraints.maxHeight - 50),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        label.position += details.delta;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.scrim,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: label.color.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        label.text,
                        style: TextStyle(
                          color: label.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPreviewCard(_PreviewPalette palette) {
    final controller = _videoController;
    final l10n = AppLocalizations.of(context);

    if (_videoFailed) {
      return _buildFilePreviewCard(palette);
    }
    if (controller == null || !controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            // Tap anywhere on the frame to play/pause, the way the chat's own
            // video bubbles behave.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleVideoPlayback,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isPlaying ? 0 : 1,
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: Icon(
                        Icons.play_circle_filled_rounded,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: palette.accent,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          l10n.mediaPreviewScreenFileSize(
                            formatBytes(widget.fileBytes.length),
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Documents and anything else without a visual preview: what it is, what
  /// it is called, how big it is.
  Widget _buildFilePreviewCard(_PreviewPalette palette) {
    final type = fileTypeDisplayFor(
      fileName: widget.fileName,
      mimeType: widget.mimeType,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showsPdfPage) _buildPdfPage(palette),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_showsPdfPage) ...[
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: type.color.withValues(alpha: 0.12),
                      border: Border.all(
                        color: type.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(type.icon, color: type.color, size: 40),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  widget.fileName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _fileSubtitle(),
                  style: TextStyle(color: palette.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "3 pages · PDF · 245 kB", matching the line the chat bubble shows once
  /// the same file has been sent.
  String _fileSubtitle() {
    final type = fileTypeDisplayFor(
      fileName: widget.fileName,
      mimeType: widget.mimeType,
    );
    final l10n = AppLocalizations.of(context);
    final parts = <String>[];

    final pages = _pdfPageCount;
    if (pages != null && pages > 0) {
      parts.add(
        pages == 1
            ? l10n.documentMessagePageCountOne
            : l10n.documentMessagePageCount(pages),
      );
    }
    parts.add(type.label);
    parts.add(formatBytes(widget.fileBytes.length));
    return parts.join(' · ');
  }

  /// The rendered first page. Holds the same height whether or not the render
  /// has landed, so the card does not jump once it does.
  Widget _buildPdfPage(_PreviewPalette palette) {
    final page = _pdfPage;
    return Container(
      width: double.infinity,
      height: 340,
      color: Colors.white,
      child: page == null
          ? Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: palette.accent,
                ),
              ),
            )
          : Image.memory(
              page,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
            ),
    );
  }

  Widget _buildAudioPreviewCard(_PreviewPalette palette) {
    final displayDuration = _duration.inSeconds > 0
        ? _duration
        : Duration(seconds: widget.duration ?? 0);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulseVal = _pulseController.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: palette.accent.withValues(alpha: 0.15 + (pulseVal * 0.15)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.3),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Mic Icon Container (Talkmos Royal Blue)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.accent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: palette.accent.withValues(
                      alpha: 0.2 + (pulseVal * 0.3),
                    ),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.mic_rounded,
                    color: palette.accent,
                    size: 36 + (pulseVal * 4),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Playback controls & timeline
              Row(
                children: [
                  IconButton(
                    onPressed: _togglePlayback,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      size: 44,
                      color: palette.accent,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            activeTrackColor: palette.accent,
                            inactiveTrackColor: palette.border,
                            thumbColor: palette.accent,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            max: displayDuration.inSeconds.toDouble() > 0
                                ? displayDuration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: (val) {
                              _audioPlayer?.seek(
                                Duration(seconds: val.toInt()),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.textMuted,
                                ),
                              ),
                              Text(
                                _formatDuration(displayDuration),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar(_PreviewPalette palette) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: palette.textMuted,
                    ),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: TextStyle(color: palette.text),
                      // Kept multiline, unlike the chat composer: a caption is
                      // written in one go rather than sent per line.
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: l10n.mediaPreviewScreenCaptionHint,
                        hintStyle: TextStyle(color: palette.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        // AppTheme's inputDecorationTheme fills inputs by
                        // default, which would paint a square inside the pill.
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              Uint8List? editedBytes;
              String finalFileName = widget.fileName;
              String finalMimeType = widget.mimeType;

              if (_isImage &&
                  (_strokes.isNotEmpty ||
                      _textLabels.isNotEmpty ||
                      _rotationQuarterTurns > 0 ||
                      _croppedBytes != null)) {
                // Show a quick progress loader
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(color: palette.accent),
                  ),
                );

                editedBytes = await _capturePng();

                if (mounted) {
                  Navigator.pop(context); // Dismiss loader
                }

                if (editedBytes != null) {
                  finalFileName =
                      'edited_${widget.fileName.replaceAll(RegExp(r'\.[^.]+$'), '')}.png';
                  finalMimeType = 'image/png';
                }
              }

              if (mounted) {
                Navigator.pop(context, {
                  'confirmed': true,
                  'caption': _captionController.text.trim(),
                  'fileBytes': editedBytes ?? _workingBytes,
                  'fileName': finalFileName,
                  'mimeType': finalMimeType,
                });
              }
            },
            // Same CircleAvatar the chat composer uses, at the same radius and
            // icon size, rather than a hand-rolled circle a couple of pixels off.
            child: CircleAvatar(
              radius: 24,
              backgroundColor: palette.accent,
              child: Icon(
                Icons.send_rounded,
                color: palette.onAccent,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for doodle drawing canvas strokes
class StrokePainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  StrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
}
