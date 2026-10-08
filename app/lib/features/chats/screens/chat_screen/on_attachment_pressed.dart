part of 'chat_screen.dart';

extension _OnAttachmentPressed on _ChatScreenState {
  Future<void> _onAttachmentPressed(bool isDark) async {
    final choice = await showAttachmentSheet(context: context, isDark: isDark);
    if (choice == null || !mounted) return;
    switch (choice) {
      case AttachmentChoice.photos:
        await _sendGalleryMedia();
      case AttachmentChoice.camera:
        await _sendSinglePhoto(ImageSource.camera);
      case AttachmentChoice.cameraVideo:
        await _sendVideo(ImageSource.camera);
      case AttachmentChoice.document:
        await _sendDocument();
      case AttachmentChoice.contact:
        await _sendContact();
      case AttachmentChoice.location:
        await _sendLocation();
    }
  }
}
