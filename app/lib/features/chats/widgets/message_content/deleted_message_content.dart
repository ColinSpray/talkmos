import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// Replaces a bubble's body once its message has been deleted for everyone,
/// regardless of what type of media it originally carried.
class DeletedMessageContent extends StatelessWidget {
  final Color metaColor;

  const DeletedMessageContent({super.key, required this.metaColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block_rounded, size: 14, color: metaColor),
        const SizedBox(width: 6),
        Text(
          AppLocalizations.of(context).deletedMessageBody,
          style: TextStyle(
            fontSize: 14,
            color: metaColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
