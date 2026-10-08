part of 'chat_screen.dart';

extension _SendLocation on _ChatScreenState {
  Future<void> _sendLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnack(
            AppLocalizations.of(context).chatScreenLocationPermissionRequired,
            isError: true,
          );
        }
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          _showSnack(
            AppLocalizations.of(context).chatScreenTurnOnLocationServices,
            isError: true,
          );
        }
        return;
      }

      _showSnack(AppLocalizations.of(context).chatScreenGettingLocation);
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;

      final payload = SharedLocationPayload(
        lat: position.latitude,
        lng: position.longitude,
      );

      await _chatProvider.sendMessage(
        chatId: widget.chatId,
        content: payload.encode(),
        messageType: 'location',
        replyToId: _replyingToMessage?.id,
        isDirect: widget.chatType == 'direct',
      );
      _clearReplyAfterSend();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showSnack(
          AppLocalizations.of(
            context,
          ).chatScreenShareLocationFailed(e.toString()),
          isError: true,
        );
      }
    }
  }
}
