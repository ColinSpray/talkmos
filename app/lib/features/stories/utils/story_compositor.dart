import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../widgets/story_editor_models.dart';

Future<Size> decodeImageSize(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
}

Future<Uint8List> compositeStoryImage({
  required Uint8List bytes,
  int rotationQuarterTurns = 0,
  ColorFilter? colorFilter,
  List<StoryTextItem> textItems = const [],
  List<StoryStickerItem> stickerItems = const [],
}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final srcW = image.width.toDouble();
  final srcH = image.height.toDouble();
  final swapped = rotationQuarterTurns.isOdd;
  final canvasW = swapped ? srcH : srcW;
  final canvasH = swapped ? srcW : srcH;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasW, canvasH));

  canvas.save();
  canvas.translate(canvasW / 2, canvasH / 2);
  canvas.rotate(rotationQuarterTurns * math.pi / 2);
  canvas.translate(-srcW / 2, -srcH / 2);
  final imagePaint = Paint();
  if (colorFilter != null) imagePaint.colorFilter = colorFilter;
  canvas.drawImage(image, Offset.zero, imagePaint);
  canvas.restore();

  for (final t in textItems) {
    final painter = TextPainter(
      text: TextSpan(
        text: t.text,
        style: TextStyle(
          color: t.color,
          fontSize: t.fontSize * canvasW,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(t.position.dx * canvasW, t.position.dy * canvasH),
    );
  }

  for (final s in stickerItems) {
    final painter = TextPainter(
      text: TextSpan(
        text: s.emoji,
        style: TextStyle(fontSize: 0.14 * canvasW * s.scale),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(s.position.dx * canvasW, s.position.dy * canvasH),
    );
  }

  final picture = recorder.endRecording();
  final finalImage = await picture.toImage(canvasW.round(), canvasH.round());
  final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
