import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'call_theme_colors.dart';

void showCallParticipantsSheet(
  BuildContext context, {
  required bool isDark,
  required List<Participant> participants,
  required Participant? localParticipant,
  required String? Function(Participant participant, bool isLocal) avatarUrlFor,
  required Set<String> raisedHandIdentities,
}) {
  final l10n = AppLocalizations.of(context);

  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF161F33) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      '${participants.length} Participants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: callTextPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 76,
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, i) {
                    final p = participants[i];
                    final isLocal = p == localParticipant;
                    final rawName = p.name.isNotEmpty ? p.name : p.identity;
                    final name = isLocal
                        ? l10n.commonYou
                        : toTitleCase(rawName);
                    final avatarUrl = avatarUrlFor(p, isLocal);
                    final handRaised = raisedHandIdentities.contains(
                      p.identity,
                    );

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      leading: AvatarCircle(
                        imageUrl: avatarUrl,
                        radius: 22,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.15),
                        fallback: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: callTextPrimary(isDark),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (handRaised)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text('✋', style: TextStyle(fontSize: 16)),
                            ),
                          Icon(
                            p.isMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            size: 18,
                            color: p.isMuted
                                ? callErrorColor
                                : callSuccessColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
