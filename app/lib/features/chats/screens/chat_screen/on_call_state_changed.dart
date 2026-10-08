part of 'chat_screen.dart';

extension _OnCallStateChanged on _ChatScreenState {
  /// An incoming call can still land mid-recording — only the outgoing side
  /// can be refused. Free the mic instead of letting the two fight over it.
  void _onCallStateChanged() {
    if (!mounted || !_recorder.isRecording) return;
    if (!(_signaling?.hasActiveCallSession ?? false)) return;

    _recorder.cancel();
    _showSnack(AppLocalizations.of(context).chatScreenRecordingStoppedForCall);
  }
}
