import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../../models/shared_attachment_payloads.dart';

class LocationMessageContent extends StatelessWidget {
  final String content;
  final Color textColor;

  /// The bubble's timestamp and tick, placed on the coordinates line rather
  /// than a row of their own.
  final Widget? trailing;

  const LocationMessageContent({
    super.key,
    required this.content,
    required this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final payload = SharedLocationPayload.tryDecode(content);
    final primary = Theme.of(context).primaryColor;

    if (payload == null) {
      return Text(content, style: TextStyle(fontSize: 15, color: textColor));
    }

    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${payload.lat},${payload.lng}',
        ),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_rounded, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).locationMessageCurrentLocation,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${payload.lat.toStringAsFixed(5)}, ${payload.lng.toStringAsFixed(5)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
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
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 16, color: primary),
          ],
        ),
      ),
    );
  }
}
