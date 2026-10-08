import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Side of the bitmap handed to Android, in pixels. Large enough for the
/// expanded messaging layout, small enough to stay well under the binder
/// limit a notification is delivered through.
const int _avatarSize = 128;

/// The sender photo to draw on a notification, as PNG bytes.
///
/// Cached on disk: pushes are rendered on the sender's clock, and most of
/// them come from someone whose photo was already fetched.
Future<Uint8List?> notificationAvatar(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/notif_avatar_${url.hashCode & 0x7fffffff}.png',
    );
    if (await file.exists()) {
      // Re-fetched now and then, in case the photo was replaced at the same
      // URL.
      final age = DateTime.now().difference(await file.lastModified());
      if (age < const Duration(days: 7)) return await file.readAsBytes();
    }

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;

    // A photo small enough to ship as-is still beats no photo if the crop
    // fails (it decodes through the engine, which a push isolate may lack).
    final avatar =
        await _circleCrop(response.bodyBytes) ??
        (response.bodyBytes.length <= 200 * 1024 ? response.bodyBytes : null);
    if (avatar == null) return null;
    await file.writeAsBytes(avatar);
    return avatar;
  } catch (e) {
    debugPrint('[NotifAvatar] failed for $url: $e');
    return null;
  }
}

/// Centre-crops to a circle at [_avatarSize]. The photo goes out as-is
/// otherwise — square corners in a row of round avatars, and full resolution
/// for something drawn 40dp wide.
Future<Uint8List?> _circleCrop(Uint8List bytes) async {
  ui.Image? source;
  ui.Image? output;
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _avatarSize * 2,
    );
    source = (await codec.getNextFrame()).image;

    final side = math.min(source.width, source.height).toDouble();
    final src = ui.Rect.fromLTWH(
      (source.width - side) / 2,
      (source.height - side) / 2,
      side,
      side,
    );
    const dst = ui.Rect.fromLTWH(0, 0, _avatarSize * 1.0, _avatarSize * 1.0);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.clipPath(ui.Path()..addOval(dst), doAntiAlias: true);
    canvas.drawImageRect(
      source,
      src,
      dst,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );

    final picture = recorder.endRecording();
    output = await picture.toImage(_avatarSize, _avatarSize);
    picture.dispose();

    final data = await output.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } catch (e) {
    debugPrint('[NotifAvatar] crop failed: $e');
    return null;
  } finally {
    source?.dispose();
    output?.dispose();
  }
}
