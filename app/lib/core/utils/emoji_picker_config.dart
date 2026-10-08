import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

Config buildTalkmosEmojiConfig(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final panelBackground = isDark
      ? const Color(0xFF000814)
      : const Color(0xFFF1F5F9);
  final primary = Theme.of(context).primaryColor;

  return Config(
    emojiViewConfig: EmojiViewConfig(
      backgroundColor: panelBackground,
      columns: 8,
      emojiSizeMax: 28,
    ),
    categoryViewConfig: CategoryViewConfig(
      backgroundColor: panelBackground,
      indicatorColor: primary,
      iconColor: isDark ? Colors.white38 : Colors.grey,
      iconColorSelected: primary,
    ),
    bottomActionBarConfig: BottomActionBarConfig(
      backgroundColor: primary,
      buttonColor: primary,
      buttonIconColor: Colors.white,
    ),
    searchViewConfig: SearchViewConfig(
      backgroundColor: panelBackground,
      buttonIconColor: isDark ? Colors.white54 : Colors.grey,
    ),
  );
}
