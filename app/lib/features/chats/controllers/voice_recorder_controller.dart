import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../core/services/app_permissions.dart';

/// Why a recording attempt didn't produce a file.
enum VoiceRecordingFailure { permissionDenied, tooShort, error }

/// A finished voice recording, ready to be previewed and sent.
class VoiceRecording {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final int durationSeconds;

  const VoiceRecording({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.durationSeconds,
  });
}

/// Result of stopping a recording: either a [recording] or a [failure].
class VoiceRecordingResult {
  final VoiceRecording? recording;
  final VoiceRecordingFailure? failure;
  final String? errorMessage;

  const VoiceRecordingResult.success(this.recording)
    : failure = null,
      errorMessage = null;

  const VoiceRecordingResult.failed(this.failure, [this.errorMessage])
    : recording = null;

  bool get isSuccess => recording != null;
}

class VoiceRecorderController extends ChangeNotifier {
  static const int _minimumSeconds = 1;
  static const String _mimeType = 'audio/m4a';

  final AudioRecorder _recorder = AudioRecorder();
  Timer? _ticker;
  String? _path;
  bool _isRecording = false;
  int _elapsedSeconds = 0;
  bool _disposed = false;

  bool get isRecording => _isRecording;
  int get elapsedSeconds => _elapsedSeconds;

  /// Elapsed time as `m:ss`, for display next to the recording indicator.
  String get elapsedLabel {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Begins recording. Returns false if the mic permission was refused or the
  /// recorder failed to start.
  Future<bool> start() async {
    if (_isRecording) return true;
    if (!await AppPermissions.ensureMicrophone()) return false;
    if (!await _recorder.hasPermission()) return false;

    try {
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: _path!,
      );
      _isRecording = true;
      _elapsedSeconds = 0;
      _notify();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        _notify();
      });
      return true;
    } catch (e) {
      debugPrint('[VoiceRecorder] start failed: $e');
      _reset();
      return false;
    }
  }

  /// Discards the in-progress recording.
  Future<void> cancel() async {
    _ticker?.cancel();
    try {
      await _recorder.cancel();
    } catch (e) {
      debugPrint('[VoiceRecorder] cancel failed: $e');
    }
    _reset();
  }

  /// Stops recording and reads the captured audio back. Recordings shorter
  /// than a second are discarded as accidental taps.
  Future<VoiceRecordingResult> stop() async {
    _ticker?.cancel();
    final duration = _elapsedSeconds;
    _isRecording = false;
    _elapsedSeconds = 0;
    _notify();

    if (duration < _minimumSeconds) {
      try {
        await _recorder.cancel();
      } catch (_) {
        // Nothing recoverable — the clip is being thrown away regardless.
      }
      _path = null;
      return const VoiceRecordingResult.failed(VoiceRecordingFailure.tooShort);
    }

    try {
      final path = await _recorder.stop();
      _path = null;
      if (path == null) {
        return const VoiceRecordingResult.failed(VoiceRecordingFailure.error);
      }
      final bytes = await File(path).readAsBytes();
      return VoiceRecordingResult.success(
        VoiceRecording(
          bytes: bytes,
          fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
          mimeType: _mimeType,
          durationSeconds: duration,
        ),
      );
    } catch (e) {
      _path = null;
      return VoiceRecordingResult.failed(
        VoiceRecordingFailure.error,
        e.toString(),
      );
    }
  }

  void _reset() {
    _isRecording = false;
    _elapsedSeconds = 0;
    _path = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    if (_isRecording) _recorder.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
