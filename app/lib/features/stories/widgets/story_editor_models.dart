import 'package:flutter/material.dart';

class StoryTextItem {
  String text;
  Offset position;
  Color color;
  double fontSize;

  StoryTextItem({
    required this.text,
    required this.position,
    required this.color,
    this.fontSize = 0.05,
  });
}

/// A draggable emoji "sticker" overlaid on a story image. Same
/// fractional-coordinate reasoning as [StoryTextItem].
class StoryStickerItem {
  final String emoji;
  Offset position;
  double scale;

  StoryStickerItem({
    required this.emoji,
    required this.position,
    this.scale = 1.0,
  });
}

/// One filter preset. `colorFilter == null` means "Normal" (no filter).
class StoryFilter {
  final String name;
  final ColorFilter? colorFilter;

  const StoryFilter({required this.name, this.colorFilter});
}

final List<StoryFilter> kStoryFilters = [
  const StoryFilter(name: 'Normal'),
  const StoryFilter(
    name: 'B&W',
    colorFilter: ColorFilter.matrix([
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  const StoryFilter(
    name: 'Vintage',
    colorFilter: ColorFilter.matrix([
      0.393,
      0.769,
      0.189,
      0,
      0,
      0.349,
      0.686,
      0.168,
      0,
      0,
      0.272,
      0.534,
      0.131,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  const StoryFilter(
    name: 'Vivid',
    colorFilter: ColorFilter.matrix([
      1.3148,
      -0.286,
      -0.0288,
      0,
      0,
      -0.0852,
      1.114,
      -0.0288,
      0,
      0,
      -0.0852,
      -0.286,
      1.3712,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  const StoryFilter(
    name: 'Cool',
    colorFilter: ColorFilter.matrix([
      0.9,
      0,
      0,
      0,
      0,
      0,
      1.0,
      0,
      0,
      0,
      0,
      0,
      1.15,
      0,
      20,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  const StoryFilter(
    name: 'Warm',
    colorFilter: ColorFilter.matrix([
      1.15,
      0,
      0,
      0,
      15,
      0,
      1.05,
      0,
      0,
      5,
      0,
      0,
      0.85,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
];
