import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

import '../../../core/services/gallery_save_service.dart';
import '../../../core/services/media_visibility_store.dart';
import '../../../core/theme/app_theme.dart';

String mediaVisibilityLabel(MediaVisibility value, {required bool globalOn}) {
  switch (value) {
    case MediaVisibility.always:
      return 'Always save';
    case MediaVisibility.never:
      return 'Never save';
    case MediaVisibility.followGlobal:
      return globalOn ? 'Default (saving)' : 'Default (not saving)';
  }
}

Future<bool> editChatMediaVisibility({
  required BuildContext context,
  required String chatId,
  required bool globalOn,
}) async {
  if (chatId.isEmpty) return false;

  final store = MediaVisibilityStore.instance;
  final current = store.visibilityFor(chatId);

  final selected = await showMediaVisibilitySheet(
    context: context,
    current: current,
    globalOn: globalOn,
  );
  if (selected == null || selected == current || !context.mounted) return false;

  if (selected == MediaVisibility.always) {
    final gallery = GallerySaveService.instance;
    final granted = await gallery.hasAccess() || await gallery.requestAccess();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).mediaVisibilityPermissionNeeded,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  await store.setVisibilityFor(chatId, selected);
  return true;
}

/// Per-chat "Media visibility" picker. Returns the chosen value, or null if
/// the sheet was dismissed without a choice.
Future<MediaVisibility?> showMediaVisibilitySheet({
  required BuildContext context,
  required MediaVisibility current,
  required bool globalOn,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? Colors.white : const Color(0xFF000000);
  final subColor = isDark
      ? AppTheme.darkTextSecondary
      : AppTheme.lightTextSecondary;
  final l10n = AppLocalizations.of(context);

  return showModalBottomSheet<MediaVisibility>(
    context: context,
    backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mediaVisibilitySheetTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.mediaVisibilitySheetDescription,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final option in MediaVisibility.values)
            ListTile(
              title: Text(
                mediaVisibilityLabel(option, globalOn: globalOn),
                style: TextStyle(color: textColor),
              ),
              subtitle: option == MediaVisibility.followGlobal
                  ? Text(
                      l10n.mediaVisibilitySheetFollowsGlobal,
                      style: TextStyle(fontSize: 12, color: subColor),
                    )
                  : null,
              trailing: current == option
                  ? Icon(Icons.check_rounded, color: Theme.of(ctx).primaryColor)
                  : null,
              onTap: () => Navigator.pop(ctx, option),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
