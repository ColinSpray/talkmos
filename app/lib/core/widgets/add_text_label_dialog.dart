import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

Future<String?> showAddTextLabelDialog(
  BuildContext context, {
  Color? backgroundColor,
  Color? textColor,
  Color? hintColor,
  Color? fieldAccentColor,
  Color? confirmButtonColor,
}) async {
  final l10n = AppLocalizations.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final background =
      backgroundColor ?? (isDark ? const Color(0xFF000814) : Colors.white);
  final text = textColor ?? (isDark ? Colors.white : const Color(0xFF000000));
  final hint = hintColor ?? (isDark ? Colors.white54 : Colors.grey);
  final confirm = confirmButtonColor ?? Theme.of(context).primaryColor;
  final fieldAccent = fieldAccentColor ?? confirm;
  final controller = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: background,
      title: Text(
        l10n.mediaPreviewScreenAddTextLabelTitle,
        style: TextStyle(color: text),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: TextStyle(color: text),
        decoration: InputDecoration(
          hintText: l10n.mediaPreviewScreenTypeTextHint,
          hintStyle: TextStyle(color: hint),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: fieldAccent),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: fieldAccent, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.commonCancel, style: TextStyle(color: hint)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: Text(
            l10n.commonAdd,
            style: TextStyle(color: confirm, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  return (result == null || result.isEmpty) ? null : result;
}
