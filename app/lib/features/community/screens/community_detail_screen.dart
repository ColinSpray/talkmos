import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../../features/chats/services/chat_service/chat_service.dart';
import '../../../models/community_model.dart';
import '../../../core/utils/deep_link_urls.dart';
import '../../../core/utils/titlecase_function.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/media_cache_service.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String chatId;
  final String fallbackName;
  final String? fallbackImageUrl;

  const CommunityDetailScreen({
    super.key,
    required this.chatId,
    required this.fallbackName,
    this.fallbackImageUrl,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = true;
  bool _isLeaving = false;
  String? _membersError;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    final provider = context.read<CommunityProvider>();
    if (provider.communities.isEmpty) {
      provider.loadCommunities();
    }
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
    });
    try {
      final raw = await _chatService.getCommunityMembers(widget.chatId);
      if (mounted) {
        setState(() => _members = List<Map<String, dynamic>>.from(raw));
      }
    } catch (e) {
      if (mounted) setState(() => _membersError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  CommunityModel? _resolveCommunity(CommunityProvider provider) {
    for (final c in provider.communities) {
      if (c.id == widget.chatId) return c;
    }
    return null;
  }

  String? _roleOf(String userId) {
    for (final m in _members) {
      final u = m['userId'];
      final id = u is Map ? u['_id'] : u;
      if (id == userId) return m['role'] as String?;
    }
    return null;
  }

  Future<void> _leaveCommunity() async {
    setState(() => _isLeaving = true);
    try {
      await context.read<CommunityProvider>().leaveCommunity(widget.chatId);
      AnalyticsService.logEvent('community_left');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLeaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).communityDetailScreenLeaveError(e.toString()),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _confirmLeave(String communityName) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityDetailScreenLeaveTitle),
        content: Text(
          l10n.communityDetailScreenLeaveBody(toTitleCase(communityName)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _leaveCommunity();
            },
            child: Text(
              l10n.commonLeave,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl, String name, {double size = 48}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: MediaCacheService.manager,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, error, stackTrace) =>
              _buildDefaultAvatar(name, size: size),
        ),
      );
    }
    return _buildDefaultAvatar(name, size: size);
  }

  Widget _buildDefaultAvatar(String name, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final community = _resolveCommunity(context.watch<CommunityProvider>());
    final myId = context.watch<AuthProvider>().user?.id;
    final isOwner = myId != null && _roleOf(myId) == 'owner';

    final name = (community != null && community.name.isNotEmpty)
        ? community.name
        : widget.fallbackName;
    final imageUrl = (community != null && community.imageUrl.isNotEmpty)
        ? community.imageUrl
        : widget.fallbackImageUrl;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: Text(l10n.communityDetailScreenTitle),
        backgroundColor: isDark ? const Color(0xFF0B1120) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.communityDetailScreenShareInvite,
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text:
                    '${toTitleCase(name)} on Talkmos: '
                    '${DeepLinkUrls.invite(widget.chatId)}',
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        color: Theme.of(context).primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _buildHeader(community, name, imageUrl, isDark),
            const SizedBox(height: 16),
            _buildMembersSection(isDark),
            const SizedBox(height: 24),
            if (!isOwner)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: _isLeaving ? null : () => _confirmLeave(name),
                  icon: _isLeaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    l10n.communityDetailScreenLeaveButton,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    CommunityModel? community,
    String name,
    String? imageUrl,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    final description = community?.description ?? '';
    final category = community?.category ?? '';
    final isVerified = community?.isVerified ?? false;
    final memberCount = community?.memberCount ?? _members.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      color: isDark ? const Color(0xFF141B2E) : Colors.white,
      child: Column(
        children: [
          _buildAvatar(imageUrl, name, size: 84),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  toTitleCase(name),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.verified_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ],
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.communityDetailScreenMembersCount(memberCount) +
                  (category.isNotEmpty ? ' · $category' : ''),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            _members.isNotEmpty
                ? l10n.communityDetailScreenMembersHeaderCount(_members.length)
                : l10n.communityDetailScreenMembersHeader,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF7C86A3) : const Color(0xFF8A93A8),
            ),
          ),
        ),
        if (_isLoadingMembers)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          )
        else if (_membersError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.communityDetailScreenMembersLoadError(
                    _membersError ?? '',
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
                TextButton(
                  onPressed: _loadMembers,
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141B2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _members.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 68,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9),
                    ),
                  _buildMemberTile(_members[i], isDark),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, bool isDark) {
    final user = member['userId'];
    final Map<String, dynamic> userMap = user is Map
        ? Map<String, dynamic>.from(user)
        : <String, dynamic>{};
    final String name =
        userMap['name'] ?? AppLocalizations.of(context).commonUnknown;
    final String? avatarUrl = userMap['avatarUrl'] as String?;
    final String role = (member['role'] as String?) ?? 'member';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _buildAvatar(avatarUrl, name, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              toTitleCase(name),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
            ),
          ),
          if (role != 'member')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role[0].toUpperCase() + role.substring(1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
