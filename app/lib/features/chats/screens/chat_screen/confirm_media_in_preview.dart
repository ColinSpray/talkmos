part of 'chat_screen.dart';

extension _ConfirmMediaInPreview on _ChatScreenState {
  Future<Map<String, dynamic>?> _confirmMediaInPreview(
    PickedMedia media, {
    int? durationSeconds,
  }) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          fileBytes: media.bytes,
          fileName: media.fileName,
          mimeType: media.mimeType,
          duration: durationSeconds ?? 0,
        ),
      ),
    );
    if (result == null || result['confirmed'] != true) return null;
    return result;
  }

  /// [media] with whatever the preview screen edited folded back in.
  PickedMedia _mediaFromPreview(
    PickedMedia media,
    Map<String, dynamic> result,
  ) => media.copyWith(
    bytes: result['fileBytes'] as Uint8List?,
    fileName: result['fileName'] as String?,
    mimeType: result['mimeType'] as String?,
  );
}
