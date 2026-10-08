import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import '../utils/emoji_picker_config.dart';

Future<void> showEmojiPickerSheet(
  BuildContext context, {
  required void Function(Category? category, Emoji emoji) onEmojiSelected,
  double height = 320,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF000814) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SizedBox(
      height: height,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          Navigator.pop(sheetContext);
          onEmojiSelected(category, emoji);
        },
        config: buildTalkmosEmojiConfig(context),
      ),
    ),
  );
}
