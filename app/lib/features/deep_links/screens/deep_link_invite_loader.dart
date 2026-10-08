import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/community_model.dart';
import '../../../providers/providers.dart';
import '../../chats/services/chat_service/chat_service.dart';
import '../../community/screens/community_detail_screen.dart';
import 'deep_link_auth_guard.dart';
import 'deep_link_error_view.dart';

class DeepLinkInviteLoader extends StatefulWidget {
  final String communityId;

  const DeepLinkInviteLoader({super.key, required this.communityId});

  @override
  State<DeepLinkInviteLoader> createState() => _DeepLinkInviteLoaderState();
}

class _DeepLinkInviteLoaderState extends State<DeepLinkInviteLoader> {
  CommunityModel? _preview;
  String? _error;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (redirectIfSignedOut(context)) return;
    try {
      final preview = await ChatService().getCommunityPreview(
        widget.communityId,
      );
      if (mounted) setState(() => _preview = preview);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _openCommunity() {
    final preview = _preview!;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          chatId: widget.communityId,
          fallbackName: preview.name,
          fallbackImageUrl: preview.imageUrl,
        ),
      ),
    );
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isJoining = true);
    try {
      await context.read<CommunityProvider>().joinCommunity(widget.communityId);
      if (!mounted) return;
      _openCommunity();
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityScreenJoinError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return DeepLinkErrorView(message: _error!);
    }
    final preview = _preview;
    if (preview == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: preview.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: preview.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _groupFallback(theme),
                          )
                        : _groupFallback(theme),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        preview.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (preview.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified_rounded,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview.description.isNotEmpty
                      ? preview.description
                      : l10n.communityScreenNoDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: subtextColor),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.communityScreenMembersCount(preview.memberCount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isJoining
                        ? null
                        : (preview.isMember ? _openCommunity : _join),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            preview.isMember
                                ? l10n.commonOpen
                                : l10n.communityScreenJoinButton,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Stands in for the group's photo, missing or unreachable.
  Widget _groupFallback(ThemeData theme) => Container(
    color: theme.primaryColor.withValues(alpha: 0.12),
    child: Icon(Icons.groups_rounded, color: theme.primaryColor, size: 40),
  );
}
