import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talkmos/core/router/app_router.dart';
import 'package:talkmos/core/utils/deep_link_urls.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/models/recent_chat.dart';
import 'package:talkmos/providers/providers.dart';
import '../../calls/services/call_signaling/call_signaling_service.dart';
import '../../../core/services/token_manager.dart';
import '../../../core/services/media_visibility_store.dart';
import '../../chats/widgets/media_visibility_sheet.dart';
import '../../chats/services/chat_service/chat_service.dart';
import '../../chats/utils/direct_chat_peer.dart';
import '../../chats/services/socket_service/socket_service.dart';
import '../../chats/screens/chat_screen/chat_screen.dart';
import '../../chats/screens/full_screen_image_viewer.dart';
import '../../chats/screens/shared_media_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user;
  final String? chatId;

  const UserProfileScreen({super.key, required this.user, this.chatId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isMuted = false;
  bool _isProcessingAction = false;

  /// Null until the server answers, so the presence dot stays hidden rather
  /// than guessing "offline".
  bool? _isOnline;

  /// Null while unfetched, so the row can show a placeholder instead of a
  /// wrong "0" before the real count arrives.
  int? _sharedMediaCount;

  /// The chat screen underneath owns this callback slot; we chain through it
  /// and restore on dispose instead of clobbering it.
  void Function(String, bool, DateTime?)? _previousOnlineHandler;
  ChatProvider? _chatProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider ??= context.read<ChatProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncMuteStateFromChat();
      _watchPresence();
      _loadSharedMediaCount();
      // Decides which friendship action this profile offers — a chat with a
      // public account can be open long before the friends list is fetched.
      context.read<FriendProvider>().loadFriendsAndRequests(isSilent: true);
    });
  }

  /// The chat backing this profile, if one exists yet — same resolution
  /// [_findRecentChat] uses, just the id alone.
  String? get _effectiveChatId =>
      _findRecentChat()?.conversationId ?? widget.chatId;

  String get _peerId {
    if (widget.user.id.isNotEmpty) return widget.user.id;
    final chat = _findRecentChat();
    if (chat == null) return '';
    return directChatPeerId(chat, _chatProvider?.user?.id) ?? '';
  }

  Future<void> _loadSharedMediaCount() async {
    final chatId = _effectiveChatId;
    if (chatId == null || chatId.isEmpty) return;
    try {
      final page = await ChatService().getSharedMedia(chatId, limit: 1);
      if (mounted) setState(() => _sharedMediaCount = page.total);
    } catch (_) {
      // Leave it null — the row just won't show a count.
    }
  }

  void _openSharedMedia() {
    final chatId = _effectiveChatId;
    if (chatId == null || chatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).userProfileScreenStartConversationBeforeMedia,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SharedMediaScreen(chatId: chatId, title: widget.user.name),
      ),
    );
  }

  @override
  void dispose() {
    _chatProvider?.onUserOnlineStatus = _previousOnlineHandler;
    super.dispose();
  }

  void _watchPresence() {
    final chatProvider = _chatProvider;
    if (chatProvider == null) return;

    _previousOnlineHandler = chatProvider.onUserOnlineStatus;
    chatProvider.onUserOnlineStatus = (userId, online, lastSeenAt) {
      _previousOnlineHandler?.call(userId, online, lastSeenAt);
      if (userId == widget.user.id && mounted) {
        setState(() => _isOnline = online);
      }
    };
    context.read<SocketService>().checkUserOnline(widget.user.id);
  }

  /// Mirrors the conversation's real mute preference so the toggle reflects
  /// what's actually stored rather than a per-visit default.
  void _syncMuteStateFromChat() {
    final chat = _findRecentChat();
    if (chat != null && mounted) {
      setState(() => _isMuted = chat.isMuted);
    }
  }

  RecentChat? _findRecentChat() {
    final chats = _chatProvider?.recentChats ?? const <RecentChat>[];
    for (final c in chats) {
      if (widget.chatId != null && c.conversationId == widget.chatId) return c;
      if (c.chatType == 'direct' &&
          c.members.any((m) => m.id == widget.user.id)) {
        return c;
      }
    }
    return null;
  }

  /// Mutes/unmutes the conversation for real via the chat preference API —
  /// this used to be local screen state that reset on every visit.
  Future<void> _setMuted(bool muted) async {
    final chat = _findRecentChat();
    if (chat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).userProfileScreenStartConversationBeforeMuting,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isMuted = muted);
    if (chat.isMuted != muted) {
      await _chatProvider?.toggleMuteChat(chat);
    }
  }

  MediaVisibility get _mediaVisibility {
    final chatId = _effectiveChatId;
    if (chatId == null || chatId.isEmpty) return MediaVisibility.followGlobal;
    return MediaVisibilityStore.instance.visibilityFor(chatId);
  }

  Future<void> _pickMediaVisibility() async {
    final chatId = _effectiveChatId;
    if (chatId == null || chatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).userProfileScreenStartConversationBeforeChanging,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final changed = await editChatMediaVisibility(
      context: context,
      chatId: chatId,
      globalOn: context.read<SettingsProvider>().saveToPhotos,
    );
    if (changed && mounted) setState(() {});
  }

  Future<String> _resolveDirectChatId() async {
    if (widget.chatId != null && widget.chatId!.isNotEmpty) {
      return widget.chatId!;
    }
    final chatProvider = context.read<ChatProvider>();
    for (final c in chatProvider.recentChats) {
      if (c.chatType == 'direct') {
        final isMember = c.members.any((m) => m.id == widget.user.id);
        if (isMember || c.id == widget.user.id) {
          return c.id;
        }
      }
    }
    return await ChatService().generateDirectChatId(widget.user.id);
  }

  Future<void> _openDirectChat() async {
    if (widget.chatId != null && widget.chatId!.isNotEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isProcessingAction = true);
    try {
      final resolvedId = await _resolveDirectChatId();
      if (!mounted) return;
      setState(() => _isProcessingAction = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            activeUser: widget.user,
            chatId: resolvedId,
            chatType: 'direct',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingAction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).userProfileScreenCouldNotOpenChat('$e'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _startCall({required bool isVideo}) async {
    if (_isProcessingAction) return;
    final token = TokenManager.token;
    if (token == null) return;
    setState(() => _isProcessingAction = true);
    try {
      final resolvedId = await _resolveDirectChatId();
      final signalingService = context.read<CallSignalingService>();
      final authProvider = context.read<AuthProvider>();
      final myName =
          authProvider.user?.name ?? AppLocalizations.of(context).commonMe;

      final outcome = await signalingService.startOutgoingCall(
        chatId: resolvedId,
        calleeId: widget.user.id,
        calleeName: widget.user.name,
        calleeAvatar: widget.user.avatarUrl,
        initiatorName: myName,
        isVideo: isVideo,
      );

      if (!mounted) return;
      setState(() => _isProcessingAction = false);
      if (outcome == CallStartOutcome.invitedToActiveCall) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).commonAddedToCall(toTitleCase(widget.user.name)),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      context.push(AppRoutes.activeCall);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingAction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).userProfileScreenFailedToStartCall('$e'),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = widget.user;
    final primary = theme.primaryColor;

    final bgColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final authProvider = context.watch<AuthProvider>();
    final myId = authProvider.user?.id ?? '';
    final isMe = myId.isNotEmpty && myId == user.id;
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    final isBlocked = context.watch<BlockProvider>().isBlocked(user.id);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: textColor),
            onPressed: () => _showMoreMenu(isDark, textColor),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildAvatar(user, hasAvatar, isDark, primary),
              const SizedBox(height: 16),
              _buildNameRow(user, textColor, primary),
              const SizedBox(height: 6),
              Text(
                user.username != null && user.username!.isNotEmpty
                    ? '@${user.username!.toUpperCase()}'
                    : (user.phone ?? user.email ?? ''),
                style: TextStyle(
                  fontSize: 15,
                  color: subtextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),

              if (!isMe) ...[
                const SizedBox(height: 28),
                _buildQuickActions(primary, textColor, isBlocked),
              ],

              const SizedBox(height: 32),
              _buildInfoRows(
                user,
                isMe,
                textColor,
                subtextColor,
                primary,
                isBlocked,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header pieces ─────────────────────────────────────────────────────────

  Widget _buildAvatar(
    UserModel user,
    bool hasAvatar,
    bool isDark,
    Color primary,
  ) {
    return GestureDetector(
      onTap: hasAvatar
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(
                  imageUrl: user.avatarUrl!,
                  heroTag: 'user_avatar_${user.id}',
                ),
              ),
            )
          : null,
      child: Hero(
        tag: 'user_avatar_${user.id}',
        child: SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            children: [
              AvatarCircle(
                imageUrl: user.avatarUrl,
                radius: 66,
                backgroundColor: primary.withValues(alpha: 0.12),
                fallback: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
              // Presence dot, driven by the live socket check rather than a
              // static field — absent until the server actually answers.
              if (_isOnline == true)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF000000) : Colors.white,
                        width: 4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameRow(UserModel user, Color textColor, Color primary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            toTitleCase(user.name),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (user.isVerified) ...[
          const SizedBox(width: 8),
          Icon(Icons.verified_rounded, color: primary, size: 24),
        ],
      ],
    );
  }

  Widget _buildQuickActions(Color primary, Color textColor, bool isBlocked) {
    final l10n = AppLocalizations.of(context);
    final disabled = _isProcessingAction || isBlocked;
    final friendAction = _buildFriendAction(primary, textColor, isBlocked);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.chat_bubble_rounded,
          label: l10n.userProfileScreenMessage,
          primary: primary,
          textColor: textColor,
          onTap: disabled ? null : _openDirectChat,
        ),
        _buildActionButton(
          icon: Icons.call_rounded,
          label: l10n.userProfileScreenAudioCall,
          primary: primary,
          textColor: textColor,
          onTap: disabled ? null : () => _startCall(isVideo: false),
        ),
        _buildActionButton(
          icon: Icons.videocam_rounded,
          label: l10n.userProfileScreenVideoCall,
          primary: primary,
          textColor: textColor,
          onTap: disabled ? null : () => _startCall(isVideo: true),
        ),
        if (friendAction != null) friendAction,
      ],
    );
  }

  Widget? _buildFriendAction(Color primary, Color textColor, bool isBlocked) {
    final l10n = AppLocalizations.of(context);
    final friends = context.watch<FriendProvider>();

    // No id, no action: the request would go out with an empty receiver, and
    // the friendship lookup would answer "not a friend" about nobody.
    final peerId = _peerId;
    if (peerId.isEmpty) return null;

    if (!friends.hasLoadedFriends) return null;

    switch (friends.getFriendshipStatus(peerId)) {
      case FriendshipStatus.accepted:
        return null;

      case FriendshipStatus.sent:
        return _buildActionButton(
          icon: Icons.schedule_rounded,
          label: l10n.userProfileScreenRequested,
          primary: primary,
          textColor: textColor,
          onTap: null,
        );

      case FriendshipStatus.received:
        return _buildActionButton(
          icon: Icons.person_add_alt_1_rounded,
          label: l10n.userProfileScreenAcceptRequest,
          primary: primary,
          textColor: textColor,
          onTap: isBlocked ? null : _acceptFriendRequest,
        );

      case FriendshipStatus.none:
      case FriendshipStatus.rejected:
        return _buildActionButton(
          icon: Icons.person_add_alt_1_rounded,
          label: l10n.userProfileScreenAddFriend,
          primary: primary,
          textColor: textColor,
          onTap: isBlocked ? null : _sendFriendRequest,
        );
    }
  }

  Future<void> _sendFriendRequest() async {
    final l10n = AppLocalizations.of(context);
    final peerId = _peerId;
    if (peerId.isEmpty) return;
    try {
      await context.read<FriendProvider>().sendRequest(peerId);
      _showSnack(l10n.userProfileScreenRequestSent);
    } catch (e) {
      _showSnack(l10n.userProfileScreenRequestFailed(e.toString()));
    }
  }

  Future<void> _acceptFriendRequest() async {
    final l10n = AppLocalizations.of(context);
    final friends = context.read<FriendProvider>();
    final peerId = _peerId;
    final request = friends.pendingIncomingRequests.firstWhere(
      (r) => r['sender'] is Map && r['sender']['_id'] == peerId,
      orElse: () => const <String, dynamic>{},
    );
    final requestId = request['_id']?.toString();
    if (requestId == null || requestId.isEmpty) return;

    try {
      await friends.acceptRequest(requestId);
      _showSnack(l10n.userProfileScreenRequestAccepted);
    } catch (e) {
      _showSnack(l10n.userProfileScreenRequestFailed(e.toString()));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color primary,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    // Flexible because the row now holds up to four of these, and the labels
    // grow with the system font.
    return Flexible(
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primary, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info rows ─────────────────────────────────────────────────────────────

  Widget _buildInfoRows(
    UserModel user,
    bool isMe,
    Color textColor,
    Color subtextColor,
    Color primary,
    bool isBlocked,
  ) {
    final l10n = AppLocalizations.of(context);
    final bio = (user.bio != null && user.bio!.isNotEmpty)
        ? user.bio!
        : l10n.userProfileScreenDefaultBio;

    return Column(
      children: [
        _InfoRow(
          icon: Icons.person_outline_rounded,
          title: l10n.commonAbout,
          subtitle: bio,
          primary: primary,
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        if (user.username != null && user.username!.isNotEmpty)
          _InfoRow(
            icon: Icons.alternate_email_rounded,
            title: l10n.userProfileScreenTalkmosUsername,
            subtitle: '@${user.username!.toUpperCase()}',
            primary: primary,
            textColor: textColor,
            subtextColor: subtextColor,
            onTap: () => _copy(
              '@${user.username}',
              l10n.userProfileScreenUsernameCopied,
            ),
          ),
        if (user.phone != null && user.phone!.isNotEmpty)
          _InfoRow(
            icon: Icons.phone_outlined,
            title: l10n.userProfileScreenPhone,
            subtitle: user.phone!,
            primary: primary,
            textColor: textColor,
            subtextColor: subtextColor,
            onTap: () =>
                _copy(user.phone!, l10n.userProfileScreenPhoneNumberCopied),
          ),
        _InfoRow(
          icon: Icons.photo_library_outlined,
          title: l10n.userProfileScreenSharedMedia,
          subtitle: _sharedMediaCount != null ? '$_sharedMediaCount' : null,
          primary: primary,
          textColor: textColor,
          subtextColor: subtextColor,
          onTap: _openSharedMedia,
        ),

        if (!isMe) ...[
          const SizedBox(height: 8),
          Divider(height: 1, color: subtextColor.withValues(alpha: 0.15)),
          const SizedBox(height: 8),

          _InfoRow(
            icon: Icons.notifications_none_rounded,
            title: l10n.commonNotifications,
            subtitle: _isMuted
                ? l10n.userProfileScreenMuted
                : l10n.userProfileScreenOn,
            primary: primary,
            textColor: textColor,
            subtextColor: subtextColor,
            trailing: Switch(
              value: !_isMuted,
              activeThumbColor: Colors.white,
              activeTrackColor: primary,
              onChanged: (on) => _setMuted(!on),
            ),
          ),

          _InfoRow(
            icon: Icons.photo_library_outlined,
            title: l10n.userProfileScreenMediaVisibility,
            subtitle: mediaVisibilityLabel(
              _mediaVisibility,
              globalOn: context.watch<SettingsProvider>().saveToPhotos,
            ),
            primary: primary,
            textColor: textColor,
            subtextColor: subtextColor,
            onTap: _pickMediaVisibility,
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: subtextColor.withValues(alpha: 0.15)),
          const SizedBox(height: 8),

          _InfoRow(
            icon: isBlocked
                ? Icons.check_circle_outline_rounded
                : Icons.block_rounded,
            title: isBlocked
                ? l10n.userProfileScreenUnblockContact
                : l10n.userProfileScreenBlockContact,
            primary: isBlocked ? primary : Colors.redAccent,
            textColor: isBlocked ? primary : Colors.redAccent,
            subtextColor: subtextColor,
            onTap: () => _toggleBlock(isBlocked),
          ),
        ],
      ],
    );
  }

  void _copy(String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggleBlock(bool isCurrentlyBlocked) async {
    final l10n = AppLocalizations.of(context);
    final user = widget.user;
    final name = toTitleCase(user.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isCurrentlyBlocked
              ? l10n.userProfileScreenUnblockConfirmTitle(name)
              : l10n.userProfileScreenBlockConfirmTitle(name),
        ),
        content: Text(
          isCurrentlyBlocked
              ? l10n.userProfileScreenUnblockConfirmBody
              : l10n.userProfileScreenBlockConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isCurrentlyBlocked ? l10n.commonUnblock : l10n.commonBlock,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final blockProvider = context.read<BlockProvider>();
      if (isCurrentlyBlocked) {
        await blockProvider.unblockUser(user.id);
      } else {
        await blockProvider.blockUser(user);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyBlocked
                ? l10n.userProfileScreenUnblockedToast(name)
                : l10n.userProfileScreenBlockedToast(name),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.userProfileScreenFailedToUpdateBlockStatus('$e'),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showMoreMenu(bool isDark, Color textColor) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF000814) : Colors.white,
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
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.share_outlined, color: textColor),
              title: Text(
                l10n.userProfileScreenShareContact,
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                Navigator.pop(ctx);
                final u = widget.user;
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${toTitleCase(u.name)} on Talkmos: '
                        '${DeepLinkUrls.chat(u.id)}',
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A single flat row in the profile's info list.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color primary;
  final Color textColor;
  final Color subtextColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.primary,
    required this.textColor,
    required this.subtextColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 26),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 14, color: subtextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: subtextColor,
                  size: 26,
                ),
          ],
        ),
      ),
    );
  }
}
