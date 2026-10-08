import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// Name + description editing sheet. [onSave] is invoked after the sheet
/// closes, so it's the caller's job to await the actual save calls.
void showGroupEditInfoSheet({
  required BuildContext context,
  required bool isDark,
  required Color textColor,
  required TextEditingController nameController,
  required TextEditingController descriptionController,
  required bool isSavingName,
  required bool isSavingDescription,
  required VoidCallback onSave,
}) {
  final l10n = AppLocalizations.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.groupProfileScreenEditGroupInfo,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: l10n.groupProfileScreenGroupNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: descriptionController,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: l10n.groupProfileScreenDescriptionLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSavingName || isSavingDescription
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          onSave();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.commonSave),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
