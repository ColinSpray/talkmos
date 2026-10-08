import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../../core/widgets/talkmos_app_bar.dart';
import '../../../core/widgets/talkmos_list_tile.dart';
import '../../../models/user_model.dart';
import '../../../models/community_model.dart';
import '../../../models/chat_message_model.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../../../core/utils/titlecase_function.dart';
import '../../chats/screens/chat_screen/chat_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/media_cache_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadCommunities();
    });
  }

  Future<void> _fetchCommunities() =>
      context.read<CommunityProvider>().loadCommunities();

  Future<void> _joinCommunity(String communityId) async {
    try {
      await context.read<CommunityProvider>().joinCommunity(communityId);
      AnalyticsService.logEvent('community_joined');
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context).communityScreenJoinedSuccess,
          success: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context).communityScreenJoinError(e.toString()),
          success: false,
        );
      }
    }
  }

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// A community IS a chat (chatType: 'community'), so its own `id`
  /// is the chat id — there is no separate `chatId` field on the item.
  void _openCommunityChat(CommunityModel item) async {
    final chatId = item.id;

    if (!item.isMember) {
      await _joinCommunity(chatId);
    }

    if (chatId.isNotEmpty && mounted) {
      final userModel = UserModel(
        id: item.id,
        name: item.name.isNotEmpty
            ? item.name
            : AppLocalizations.of(context).communityScreenDefaultName,
        avatarUrl: item.imageUrl,
      );

      context.read<ChatProvider>().getMessages(chatId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            activeUser: userModel,
            chatId: chatId,
            chatType: 'community',
          ),
        ),
      );
    }
  }

  void _showCreateCommunityBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateCommunityBottomSheet(),
    );
  }

  Widget _buildAvatar(String? imageUrl, String name, {double size = 52}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: MediaCacheService.manager,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) =>
              _buildDefaultAvatar(name, size: size),
        ),
      );
    }
    return _buildDefaultAvatar(name, size: size);
  }

  Widget _buildDefaultAvatar(String name, {double size = 52}) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<CommunityProvider>();
    final myCommunities = state.yourCommunities;
    final discoverCommunities = state.discoverCommunities;
    final isLoading = state.isLoading;
    final communities = state.communities;
    final error = state.error;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF7F7FB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: TalkmosAppBar(
        actions: [
          TalkmosAppBarAction(
            icon: Icons.search_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    ).communityScreenSearchComingSoon,
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          TalkmosNotificationAction(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    ).communityScreenNotificationsComingSoon,
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community_fab',
        onPressed: _showCreateCommunityBottomSheet,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCommunities,
        color: Theme.of(context).primaryColor,
        child: Skeletonizer(
          enabled: isLoading && communities.isEmpty,
          child: isLoading && communities.isEmpty
              ? _buildLoadingSkeleton()
              : error != null
              ? _buildErrorState(error, isDark)
              : communities.isEmpty
              ? _buildEmptyOnboarding(isDark)
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  children: [
                    // New community entry — WhatsApp-style plain row
                    _buildNewCommunityTile(isDark),

                    if (myCommunities.isNotEmpty) ...[
                      _sectionLabel(
                        AppLocalizations.of(
                          context,
                        ).communityScreenYourCommunities,
                        isDark,
                      ),
                      ...myCommunities.map(
                        (item) => _buildCommunityCard(item, isDark),
                      ),
                    ],

                    if (discoverCommunities.isNotEmpty) ...[
                      _sectionLabel(
                        AppLocalizations.of(
                          context,
                        ).communityScreenDiscoverSection,
                        isDark,
                      ),
                      ...discoverCommunities.map(
                        (item) => _buildDiscoverCard(item, isDark),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 40,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).communityScreenLoadError,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchCommunities,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context).commonRetry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: isDark ? const Color(0xFF7C86A3) : const Color(0xFF8A93A8),
        ),
      ),
    );
  }

  Widget _buildNewCommunityTile(bool isDark) {
    final cardColor = isDark ? const Color(0xFF141B2E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TalkmosListTile(
        backgroundColor: cardColor,
        borderRadius: BorderRadius.circular(16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.groups_2_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        title: Text(
          AppLocalizations.of(context).communityScreenNewCommunity,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF000000),
          ),
        ),
        onTap: _showCreateCommunityBottomSheet,
      ),
    );
  }

  /// A joined community — header row + a nested "Announcements" row,
  /// connected with a thin vertical rule, mirroring WhatsApp's layout.
  Widget _buildCommunityCard(CommunityModel item, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final String name = item.name.isNotEmpty
        ? item.name
        : l10n.communityScreenUntitled;
    final String desc = item.description;
    final int memberCount = item.memberCount;

    final cardColor = isDark ? const Color(0xFF141B2E) : Colors.white;
    final lineColor = isDark
        ? const Color(0xFF232B40)
        : const Color(0xFFE8E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TalkmosListTile(
              borderRadius: BorderRadius.zero,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              leading: _buildAvatar(item.imageUrl, name, size: 52),
              title: Text(
                toTitleCase(name),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF000000),
                ),
              ),
              subtitle: desc.isNotEmpty
                  ? Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF8993AC)
                            : const Color(0xFF6B7280),
                      ),
                    )
                  : null,
            ),
            // Connector + Announcements sub-row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Center(
                      child: Container(width: 2, height: 40, color: lineColor),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : const Color(0xFFF4F4FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TalkmosListTile(
                        borderRadius: BorderRadius.circular(12),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5F9F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: Color(0xFF10B981),
                            size: 17,
                          ),
                        ),
                        title: Text(
                          l10n.communityScreenAnnouncements,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF000000),
                          ),
                        ),
                        subtitle: Text(
                          l10n.communityScreenMembersCount(memberCount),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark
                              ? const Color(0xFF4B5570)
                              : const Color(0xFFB8BECC),
                        ),
                        onTap: () => _openCommunityChat(item),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverCard(CommunityModel item, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final String name = item.name.isNotEmpty
        ? item.name
        : l10n.communityScreenUntitled;
    final String desc = item.description.isNotEmpty
        ? item.description
        : l10n.communityScreenNoDescription;
    final int memberCount = item.memberCount;
    final bool isMember = item.isMember;

    final ChatMessageModel? lastMessage = item.lastMessage;

    String? preview;
    if (lastMessage != null) {
      switch (lastMessage.messageType) {
        case MessageType.image:
          preview = l10n.communityScreenPreviewPhoto;
          break;
        case MessageType.video:
          preview = l10n.communityScreenPreviewVideo;
          break;
        case MessageType.audio:
        case MessageType.voice:
          preview = l10n.communityScreenPreviewAudio;
          break;
        case MessageType.file:
          preview = l10n.communityScreenPreviewFile;
          break;
        default:
          preview = lastMessage.content.isNotEmpty ? lastMessage.content : null;
      }
    }

    final cardColor = isDark ? const Color(0xFF141B2E) : Colors.white;
    final subTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final pillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openCommunityChat(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(item.imageUrl, name, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              toTitleCase(name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF000000),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: pillColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l10n.communityScreenMembersCount(memberCount),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: subTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview ?? desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: subTextColor),
                      ),
                      const SizedBox(height: 10),
                      if (isMember)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.communityScreenJoinedLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.10),
                              foregroundColor: Theme.of(context).primaryColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => _joinCommunity(item.id),
                            child: Text(
                              l10n.communityScreenJoinButton,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Bone.square(
                    size: 52,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Bone.text(width: 120),
                        SizedBox(height: 6),
                        Bone.text(width: 180),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyOnboarding(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).communityScreenIntroTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).communityScreenIntroBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showCreateCommunityBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).communityScreenStartButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}

// ── Create Community Bottom Sheet ──────────────────────────────────────────

class _CreateCommunityBottomSheet extends StatefulWidget {
  const _CreateCommunityBottomSheet();

  @override
  State<_CreateCommunityBottomSheet> createState() =>
      _CreateCommunityBottomSheetState();
}

class _CreateCommunityBottomSheetState
    extends State<_CreateCommunityBottomSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Tech';
  bool _isCreating = false;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  final List<String> _categories = [
    'Tech',
    'Startup',
    'Music',
    'Travel',
    'Health',
    'Gaming',
    'Study',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final file = await pickImageFrom(ImageSource.gallery, imageQuality: 85);
      if (file == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final mediaUrl = await uploadPickedImage(file);

      if (mounted) {
        setState(() {
          _uploadedImageUrl = mediaUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).communityScreenImageUploadError(e.toString()),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      await context.read<CommunityProvider>().createCommunity(
        name: name,
        description: _descController.text.trim(),
        category: _selectedCategory,
        imageUrl: _uploadedImageUrl,
      );
      AnalyticsService.logEvent('community_created');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.communityScreenCreateSuccess),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final sheetBgColor = isDark ? const Color(0xFF000814) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final inputBgColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFF1F5F9);

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: sheetBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.communityScreenNewCommunity,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey : Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Avatar Placeholder
              Center(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          image:
                              _uploadedImageUrl != null &&
                                  _uploadedImageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    _uploadedImageUrl!,
                                    cacheManager: MediaCacheService.manager,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _isUploadingImage
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).primaryColor,
                                  strokeWidth: 3,
                                ),
                              )
                            : (_uploadedImageUrl == null
                                  ? Center(
                                      child: Icon(
                                        Icons.groups_rounded,
                                        size: 40,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    )
                                  : null),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Input Fields
              TextField(
                controller: _nameController,
                maxLength: 30,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: l10n.communityScreenNameLabel,
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: l10n.communityScreenDescriptionLabel,
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Label
              Text(
                l10n.communityScreenCategoryLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),

              // Horizontal Category Chips
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        selectedColor: Theme.of(context).primaryColor,
                        backgroundColor: isDark
                            ? const Color(0xFF000000)
                            : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : (isDark
                                      ? const Color(0xFF000E23)
                                      : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isCreating ? null : _submit,
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.communityScreenCreateButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
