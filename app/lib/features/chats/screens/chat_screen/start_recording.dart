part of 'chat_screen.dart';

extension _StartRecording on _ChatScreenState {
  void _startRecording() async {
    if (context.read<CallSignalingService>().hasActiveCallSession) {
      _showSnack(AppLocalizations.of(context).chatScreenRecordWhileInCall);
      return;
    }
    final started = await _recorder.start();
    if (!started && mounted) {
      _showSnack(AppLocalizations.of(context).chatScreenMicPermissionDenied);
    }
  }
}
