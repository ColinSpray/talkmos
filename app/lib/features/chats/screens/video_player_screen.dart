import 'dart:async';
import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/media_cache_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String heroTag;
  final String? fileName;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.heroTag,
    this.fileName,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cacheKey = widget.fileName != null && widget.fileName!.isNotEmpty
          ? widget.fileName!
          : 'video_${widget.videoUrl.hashCode}.mp4';
      final file = await MediaCacheService().getCachedFile(
        widget.videoUrl,
        fileName: cacheKey,
      );
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
      controller.play();
      _scheduleHideControls();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).videoPlayerScreenLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      final controller = _controller;
      if (mounted && controller != null && controller.value.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHideControls();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
        _scheduleHideControls();
      }
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: widget.heroTag,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _load,
                            child: Text(
                              AppLocalizations.of(context).commonRetry,
                            ),
                          ),
                        ],
                      )
                    : controller != null
                    ? GestureDetector(
                        onTap: _toggleControls,
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // ── Back button ──────────────────────────────────────────────
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // ── Play/pause + seek bar ────────────────────────────────────
            if (controller != null && _controlsVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: EdgeInsets.zero,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _fmt(controller.value.position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _togglePlayback,
                          ),
                          Text(
                            _fmt(controller.value.duration),
                            style: const TextStyle(
                              color: Colors.white70,
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
}
