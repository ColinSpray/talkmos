import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// A plain text message's body, collapsed behind a "Read more" once it runs
/// past [collapsedMaxLines].
class TextMessageContent extends StatelessWidget {
  /// Chosen to stay under a phone's half-screen at the default font size, so a
  /// long message never buries the ones after it.
  static const int collapsedMaxLines = 12;

  final String content;
  final Color textColor;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const TextMessageContent({
    super.key,
    required this.content,
    required this.textColor,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 15, color: textColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Nothing to measure against an unbounded width, and the toggle would
        // be meaningless on a line that can never wrap.
        if (!constraints.maxWidth.isFinite || onToggleExpanded == null) {
          return Text(content, style: style);
        }

        final painter = TextPainter(
          text: TextSpan(text: content, style: style),
          maxLines: collapsedMaxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        if (!overflows) return Text(content, style: style);

        final l10n = AppLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: style,
              maxLines: isExpanded ? null : collapsedMaxLines,
              overflow: isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            GestureDetector(
              onTap: onToggleExpanded,
              // Opaque so the gap around the label is part of the target
              // rather than a hole that selects the message instead.
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text(
                  isExpanded
                      ? l10n.chatBubbleReadLess
                      : l10n.chatBubbleReadMore,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
