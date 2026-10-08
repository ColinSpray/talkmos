import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../../core/services/media_cache_service.dart';
import '../../utils/voice_waveform.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final Color textColor;
  final Color metaColor;
  final bool isMe;

  /// Sits on the same line as the clip's duration — the bubble puts its
  /// timestamp and tick here rather than on a line of their own.
  final Widget? trailing;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    required this.textColor,
    required this.metaColor,
    required this.isMe,
    this.trailing,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  static const double _buttonSize = 40;
  static const double _waveHeight = 26;

  final AudioPlayer _player = AudioPlayer();
  bool _isLoading = false;
  bool _isLoaded = false;
  bool _failed = false;

  late final List<double> _barHeights = voiceWaveformBars(widget.audioUrl);

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (widget.audioUrl.isEmpty || _isLoading) return;

    if (_player.playerState.playing) {
      await _player.pause();
      return;
    }
    if (_isLoaded) {
      await _player.play();
      return;
    }

    setState(() {
      _isLoading = true;
      _failed = false;
    });
    try {
      final file = await MediaCacheService().getCachedFile(
        widget.audioUrl,
        fileName: 'audio_${widget.audioUrl.hashCode}.mp3',
      );
      await _player.setFilePath(file.path);
      _isLoaded = true;
      await _player.play();
    } catch (e) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Derived from the bubble's own text colour so it holds up on all four
    // bubble surfaces. A fixed white was invisible on the light outgoing
    // bubble, which is the one most of these are sent from.
    final Color played = widget.isMe
        ? widget.textColor.withValues(alpha: 0.95)
        : Theme.of(context).primaryColor;
    final Color unplayed = widget.textColor.withValues(alpha: 0.28);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlayButton(
          size: _buttonSize,
          isLoading: _isLoading,
          failed: _failed,
          isMe: widget.isMe,
          textColor: widget.textColor,
          accent: played,
          onTap: _togglePlayback,
          playingStream: _player.playerStateStream,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, posSnap) {
              final position = posSnap.data ?? Duration.zero;
              final total =
                  _player.duration ??
                  Duration(seconds: widget.durationSeconds.clamp(0, 99999));
              final totalMs = total.inMilliseconds.clamp(1, 1 << 30);
              final progress = (position.inMilliseconds / totalMs).clamp(
                0.0,
                1.0,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      void seekToDx(double dx) {
                        if (!_isLoaded || constraints.maxWidth <= 0) return;
                        final frac = (dx / constraints.maxWidth).clamp(
                          0.0,
                          1.0,
                        );
                        _player.seek(
                          Duration(milliseconds: (frac * totalMs).round()),
                        );
                      }

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (d) =>
                            seekToDx(d.localPosition.dx),
                        onTapDown: (d) => seekToDx(d.localPosition.dx),
                        child: SizedBox(
                          height: _waveHeight,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _WaveformPainter(
                              barHeights: _barHeights,
                              progress: progress,
                              playedColor: played,
                              unplayedColor: unplayed,
                              showThumb: _isLoaded,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Expanded, so the clip length stays left and the
                      // message time is pushed to the far edge. Side by side
                      // they read as one time range.
                      Expanded(
                        child: Text(
                          // Counts up once there is a position to report, and
                          // shows the clip's length before that — a paused
                          // note keeps showing where it stopped rather than
                          // snapping back to the full duration.
                          _failed
                              ? AppLocalizations.of(
                                  context,
                                ).voiceMessageFailedToPlay
                              : _fmt(
                                  position > Duration.zero ? position : total,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: _failed
                                ? Colors.redAccent
                                : widget.metaColor,
                            fontWeight: FontWeight.w500,
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
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Play, pause, or loading — in one place so the button never changes size or
/// shape between them.
class _PlayButton extends StatelessWidget {
  final double size;
  final bool isLoading;
  final bool failed;
  final bool isMe;
  final Color textColor;
  final Color accent;
  final VoidCallback onTap;
  final Stream<PlayerState> playingStream;

  const _PlayButton({
    required this.size,
    required this.isLoading,
    required this.failed,
    required this.isMe,
    required this.textColor,
    required this.accent,
    required this.onTap,
    required this.playingStream,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // A flat fill. The old one breathed in and out on a repeating
          // animation the whole time a note played, which repainted every
          // frame and drew the eye away from the waveform.
          color: accent.withValues(alpha: isMe ? 0.20 : 0.12),
        ),
        child: Center(
          child: isLoading
              // Sized to the icon it stands in for, so the button does not
              // appear to change weight while a note is fetched.
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              : StreamBuilder<PlayerState>(
                  stream: playingStream,
                  builder: (context, snap) {
                    if (failed) {
                      return Icon(
                        Icons.refresh_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      );
                    }
                    final playing = snap.data?.playing ?? false;
                    return Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: accent,
                      size: 24,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  /// Fractions of the track height, not pixels — so the same bars render at
  /// any track size.
  final List<double> barHeights;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;
  final bool showThumb;

  _WaveformPainter({
    required this.barHeights,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
    required this.showThumb,
  });

  static const double _barWidth = 2.5;
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || barHeights.isEmpty) return;

    // Drawn to fit whatever width the bubble gave us rather than a fixed bar
    // count, so the waveform never overflows or leaves a gap at the end.
    final slot = _barWidth + _gap;
    final count = ((size.width + _gap) / slot).floor().clamp(1, 400);
    final played = Paint()..color = playedColor;
    final unplayed = Paint()..color = unplayedColor;

    for (var i = 0; i < count; i++) {
      final fraction = barHeights[i % barHeights.length];
      final barH = (fraction * size.height).clamp(3.0, size.height);
      final left = i * slot;
      final top = (size.height - barH) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, _barWidth, barH),
          const Radius.circular(1.5),
        ),
        (i + 0.5) / count <= progress ? played : unplayed,
      );
    }

    if (!showThumb) return;
    final cx = (progress * size.width).clamp(5.0, size.width - 5);
    canvas.drawCircle(
      Offset(cx, size.height / 2),
      5,
      Paint()..color = playedColor,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.showThumb != showThumb ||
      old.playedColor != playedColor ||
      old.unplayedColor != unplayedColor ||
      old.barHeights != barHeights;
}
