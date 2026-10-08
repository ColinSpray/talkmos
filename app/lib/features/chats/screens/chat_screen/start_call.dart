part of 'chat_screen.dart';

extension _StartCall on _ChatScreenState {
  Future<void> _startCall({required bool isVideo}) async {
    if (_isCalling) return;
    // The recorder holds the mic; handing it to LiveKit mid-take leaves the
    // call with no audio and the voice note truncated.
    if (_recorder.isRecording) {
      _showSnack(AppLocalizations.of(context).chatScreenCallWhileRecording);
      return;
    }
    _setState(() => _isCalling = true);
    final token = TokenManager.token;
    if (token == null) {
      _setState(() => _isCalling = false);
      return;
    }
    try {
      final signalingService = context.read<CallSignalingService>();
      final myName =
          _chatProvider.user?.name ?? AppLocalizations.of(context).commonMe;

      final outcome = await signalingService.startOutgoingCall(
        chatId: widget.chatId,
        calleeId: widget.activeUser.id,
        calleeName: widget.activeUser.name,
        calleeAvatar: widget.activeUser.avatarUrl,
        initiatorName: myName,
        isVideo: isVideo,
      );

      if (!mounted) return;
      if (outcome == CallStartOutcome.invitedToActiveCall) {
        _showSnack(
          AppLocalizations.of(
            context,
          ).commonAddedToCall(toTitleCase(widget.activeUser.name)),
        );
      }
      context.push(AppRoutes.activeCall);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).chatScreenCallStartFailed(e.toString()),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) _setState(() => _isCalling = false);
    }
  }
}
