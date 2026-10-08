import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_video_thumbnail/get_video_thumbnail.dart' as vt;
import 'package:get_video_thumbnail/index.dart' as vt;
import '../../../providers/chat_provider.dart';
import '../../../core/services/data_usage_store.dart';
import '../../../core/services/file_naming_service.dart';
import '../../../core/services/app_permissions.dart';

/// A file chosen by the user, already read into memory and named for upload.
class PickedMedia {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final int? durationSeconds;

  final Uint8List? thumbnailBytes;

  const PickedMedia({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    this.durationSeconds,
    this.thumbnailBytes,
  });

  PickedMedia copyWith({
    Uint8List? bytes,
    String? fileName,
    String? mimeType,
    Uint8List? thumbnailBytes,
  }) => PickedMedia(
    bytes: bytes ?? this.bytes,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    durationSeconds: durationSeconds,
    thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
  );

  Map<String, dynamic> toMediaMeta() => {
    'url': '',
    'thumbnail': '',
    'fileName': fileName,
    'mimeType': mimeType,
    'size': bytes.length,
    if (durationSeconds != null) 'duration': durationSeconds,
  };
}

/// Picks media off the device. Kept free of `BuildContext` so it stays a thin
/// IO wrapper — callers own any UI (previews, snackbars) around it.
class ChatMediaPicker {
  const ChatMediaPicker._();

  static final ImagePicker _picker = ImagePicker();

  static int get _imageQuality => DataUsageStore.instance.imageQuality;

  static Future<PickedMedia?> pickImage(ImageSource source) async {
    if (!await _cameraAllowed(source)) return null;
    final file = await _picker.pickImage(
      source: source,
      imageQuality: _imageQuality,
    );
    return file == null ? null : _toPickedMedia(file, 'image/jpeg');
  }

  static Future<List<PickedMedia>> pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: _imageQuality);
    return Future.wait(files.map((f) => _toPickedMedia(f, 'image/jpeg')));
  }

  static Future<List<PickedMedia>> pickGalleryMedia() async {
    final files = await _picker.pickMultipleMedia(imageQuality: _imageQuality);
    return Future.wait(files.map(_toPickedGalleryMedia));
  }

  static Future<PickedMedia> _toPickedGalleryMedia(XFile file) async {
    final mimeType = file.mimeType ?? guessMimeTypeFromExtension(file.name);
    if (mimeType.startsWith('video/')) {
      return _toPickedVideoMedia(file, mimeType);
    }
    return _toPickedMedia(file, mimeType);
  }

  static String guessMimeTypeFromExtension(String name) {
    final ext = name.toLowerCase().split('.').last;
    const videoExts = {'mp4', 'mov', 'mkv', 'webm', '3gp', 'avi', 'm4v'};
    const imageExts = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'heif',
      'bmp',
    };
    const audioExts = {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac'};

    if (!name.contains('.')) return 'application/octet-stream';
    if (videoExts.contains(ext))
      return ext == 'mov' ? 'video/quicktime' : 'video/mp4';
    if (imageExts.contains(ext)) {
      return switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'heic' || 'heif' => 'image/heic',
        'bmp' => 'image/bmp',
        _ => 'image/jpeg',
      };
    }
    if (audioExts.contains(ext))
      return ext == 'mp3' ? 'audio/mpeg' : 'audio/mp4';
    if (ext == 'pdf') return 'application/pdf';
    return 'application/octet-stream';
  }

  static Future<PickedMedia?> pickVideo(ImageSource source) async {
    if (!await _cameraAllowed(source)) return null;
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 10),
    );
    return file == null ? null : _toPickedVideoMedia(file, 'video/mp4');
  }

  static Future<PickedMedia> _toPickedVideoMedia(
    XFile file,
    String fallbackMimeType,
  ) async {
    final media = await _toPickedMedia(file, fallbackMimeType);
    Uint8List? thumbnailBytes;
    try {
      thumbnailBytes = await vt.VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 480,
        maxHeight: 480,
        timeMs: 0,
        quality: 70,
      );
    } catch (e) {
      // Not fatal — the bubble falls back to a placeholder if this is null.
      debugPrint('[ChatMediaPicker] Thumbnail generation failed: $e');
    }
    return media.copyWith(thumbnailBytes: thumbnailBytes);
  }

  static Future<PickedMedia> _toPickedMedia(
    XFile file,
    String fallbackMimeType,
  ) async {
    final bytes = await file.readAsBytes();
    final mimeType = file.mimeType ?? fallbackMimeType;
    return PickedMedia(
      bytes: bytes,
      fileName: FileNamingService.getUploadName(file.name, mimeType),
      mimeType: mimeType,
    );
  }

  static Future<bool> _cameraAllowed(ImageSource source) async =>
      source != ImageSource.camera || await AppPermissions.ensureCamera();

  static Future<PickedMedia?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final picked = result?.files.firstOrNull;
    final bytes = picked?.bytes;
    if (picked == null || bytes == null) return null;

    const mimeType = 'application/octet-stream';
    return PickedMedia(
      bytes: bytes,
      fileName: FileNamingService.getUploadName(picked.name, mimeType),
      mimeType: mimeType,
    );
  }
}

/// Sends picked media into a specific chat. Bundles the chat context so the
/// screen doesn't have to repeat chatId/isDirect on every call.
class ChatMediaSender {
  final ChatProvider chatProvider;
  final String chatId;
  final bool isDirect;

  const ChatMediaSender({
    required this.chatProvider,
    required this.chatId,
    required this.isDirect,
  });

  Future<void> send({
    required PickedMedia media,
    required String messageType,
    required String fallbackContent,
    String caption = '',
    String? replyToId,
  }) {
    return chatProvider.sendMessage(
      chatId: chatId,
      content: caption.isNotEmpty ? caption : fallbackContent,
      messageType: messageType,
      media: media.toMediaMeta(),
      replyToId: replyToId,
      isDirect: isDirect,
      fileBytes: media.bytes,
      thumbnailBytes: media.thumbnailBytes,
    );
  }

  Future<void> sendImage(
    PickedMedia media, {
    String caption = '',
    String? replyToId,
  }) => send(
    media: media,
    messageType: 'image',
    fallbackContent: '',
    caption: caption,
    replyToId: replyToId,
  );

  Future<void> sendVideo(
    PickedMedia media, {
    String caption = '',
    String? replyToId,
  }) => send(
    media: media,
    messageType: 'video',
    fallbackContent: '',
    caption: caption,
    replyToId: replyToId,
  );

  Future<void> sendDocument(
    PickedMedia media, {
    String caption = '',
    String? replyToId,
  }) => send(
    media: media,
    messageType: 'file',
    fallbackContent: '',
    caption: caption,
    replyToId: replyToId,
  );

  Future<void> sendVoice(
    PickedMedia media, {
    String caption = '',
    String? replyToId,
  }) => send(
    media: media,
    messageType: 'voice',
    fallbackContent: '',
    caption: caption,
    replyToId: replyToId,
  );
}
