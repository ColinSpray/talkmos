import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import '../../../../models/shared_attachment_payloads.dart';

/// A shared contact card. Tapping calls the number, if there is one.
class ContactMessageContent extends StatelessWidget {
  final String content;
  final Color textColor;

  /// The bubble's timestamp and tick, placed on the phone-number line rather
  /// than a row of their own.
  final Widget? trailing;

  const ContactMessageContent({
    super.key,
    required this.content,
    required this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final payload = SharedContactPayload.tryDecode(content);
    final primary = Theme.of(context).primaryColor;

    if (payload == null) {
      // Malformed/unparseable payload — fall back to raw text rather than
      // showing a broken card.
      return Text(content, style: TextStyle(fontSize: 15, color: textColor));
    }

    return GestureDetector(
      onTap: payload.phone.isEmpty
          ? null
          : () => launchUrl(Uri.parse('tel:${payload.phone}')),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: primary.withValues(alpha: 0.18),
              child: Text(
                payload.name.isNotEmpty ? payload.name[0].toUpperCase() : '?',
                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    toTitleCase(payload.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  // Rendered whenever there is a phone number or something to
                  // trail — a contact shared without a number still needs
                  // somewhere to put the timestamp.
                  if (payload.phone.isNotEmpty || trailing != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Fills the line either way, so the time lands at the
                        // right edge whether or not there is a number.
                        Expanded(
                          child: payload.phone.isEmpty
                              ? const SizedBox.shrink()
                              : Text(
                                  payload.phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (payload.phone.isNotEmpty)
              Icon(Icons.call_rounded, size: 18, color: primary),
          ],
        ),
      ),
    );
  }
}
