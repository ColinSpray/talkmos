part of 'chat_screen.dart';

extension _SendContact on _ChatScreenState {
  Future<void> _sendContact() async {
    try {
      final status = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      final granted =
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
      if (!granted) {
        if (mounted) {
          _showSnack(
            AppLocalizations.of(context).chatScreenContactsPermissionRequired,
            isError: true,
          );
        }
        return;
      }

      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone},
      );
      if (contact == null || !mounted) return;

      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number
          : '';
      final payload = SharedContactPayload(
        name: contact.displayName ?? '',
        phone: phone,
      );

      await _chatProvider.sendMessage(
        chatId: widget.chatId,
        content: payload.encode(),
        messageType: 'contact',
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
          ).chatScreenShareContactFailed(e.toString()),
          isError: true,
        );
      }
    }
  }
}
