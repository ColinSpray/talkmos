import 'dart:math';
import 'package:path/path.dart' as p;

class FileNamingService {
  static String getUploadName(String originalName, String mimeType) {
    final isMedia =
        mimeType.startsWith('image/') ||
        mimeType.startsWith('video/') ||
        mimeType.startsWith('audio/');
    final originalExt = p
        .extension(originalName)
        .replaceAll('.', '')
        .toLowerCase();
    final cleanExt = isMedia
        ? _getExtensionFromMime(mimeType)
        : (originalExt.isNotEmpty
              ? originalExt
              : _getExtensionFromMime(mimeType));
    final uuid = _generateV4Uuid();

    final prefix = mimeType.startsWith('image/') ? 'tm_image' : 'tm_file';
    return '${prefix}_$uuid.$cleanExt';
  }

  static String _generateV4Uuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));

    // Set version to 4 (0100xxxx)
    values[6] = (values[6] & 0x0F) | 0x40;
    // Set variant to RFC4122 (10xxxxxx)
    values[8] = (values[8] & 0x3F) | 0x80;

    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static String _getExtensionFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) {
      if (mimeType == 'image/png') return 'png';
      if (mimeType == 'image/gif') return 'gif';
      if (mimeType == 'image/webp') return 'webp';
      return 'jpg';
    }
    if (mimeType.startsWith('video/')) {
      if (mimeType == 'video/mp4') return 'mp4';
      return 'mov';
    }
    if (mimeType.startsWith('audio/')) {
      if (mimeType == 'audio/mpeg') return 'mp3';
      return 'm4a';
    }
    return 'bin';
  }
}
