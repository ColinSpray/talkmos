import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

Future<Uint8List?> cropImageBytes(
  BuildContext context,
  Uint8List bytes, {
  required String title,
  bool circleCrop = false,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final sourceFile = File(
      '${dir.path}/crop_source_${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await sourceFile.writeAsBytes(bytes);
    if (!context.mounted) return null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final foregroundColor =
        theme.appBarTheme.foregroundColor ??
        (isDark ? Colors.white : Colors.black);

    final cropped = await ImageCropper().cropImage(
      sourcePath: sourceFile.path,
      aspectRatio: circleCrop
          ? const CropAspectRatio(ratioX: 1, ratioY: 1)
          : null,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: backgroundColor,
          toolbarWidgetColor: foregroundColor,
          backgroundColor: backgroundColor,
          activeControlsWidgetColor: theme.primaryColor,
          cropFrameColor: theme.primaryColor,
          cropFrameStrokeWidth: 2,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.75),
          cropGridColor: Colors.white.withValues(alpha: 0.6),
          cropGridStrokeWidth: 1,
          statusBarLight: !isDark,
          navBarLight: !isDark,
          lockAspectRatio: circleCrop,
          cropStyle: circleCrop ? CropStyle.circle : CropStyle.rectangle,
        ),
        IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: circleCrop,
          cropStyle: circleCrop ? CropStyle.circle : CropStyle.rectangle,
        ),
      ],
    );
    if (cropped == null) return null;
    // Awaited inside the try, so a failed read lands in the catch below.
    return await cropped.readAsBytes();
  } catch (e) {
    debugPrint('Error cropping image: $e');
    return null;
  }
}

/// Advances a `RotatedBox`-style quarter-turn count by one 90° clockwise
/// step, wrapping back to 0 after a full rotation.
int nextQuarterTurn(int current) => (current + 1) % 4;
