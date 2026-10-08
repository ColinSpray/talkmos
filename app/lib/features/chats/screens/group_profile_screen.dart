import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../../core/services/media_visibility_store.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../services/chat_service/chat_service.dart';
import '../utils/contact_candidates.dart';
import '../utils/group_permissions.dart';
import '../widgets/group_settings_widgets.dart';
import '../widgets/media_visibility_sheet.dart';
import '../widgets/group_profile_header.dart';
import '../widgets/group_profile_loading_skeleton.dart';
import '../widgets/group_add_members_sheet.dart';
import '../widgets/group_members_sheet.dart';
import '../widgets/group_profile_menu_sheet.dart';
import '../widgets/group_edit_info_sheet.dart';
import 'group_permissions_screen.dart';
import '../../../models/recent_chat.dart';

class GroupProfileScreen extends StatefulWidget {
  final String chatId;
  final String groupName;
  final String? groupAvatarUrl;

  const GroupProfileScreen({
    super.key,
    required this.chatId,
    required this.groupName,
    this.groupAvatarUrl,
  });

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  final _chatService = ChatService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingDescription = false;
  bool _isUploadingImage = false;

  List<dynamic> _members = [];
  String? _avatarUrl;
  Map<String, dynamic> _permissions = {};
  String _myRole = 'member';

  bool get _isGroupAdmin => _myRole == 'admin' || _myRole == 'owner';
  bool get _isGroupOwner => _myRole == 'owner';

  bool _allows(String action) => groupActionAllowed(
    permissions: _permissions,
    role: _myRole,
    action: action,
  );

  bool get _canAddMembers => _allows('addMembers');
  bool get _canEditInfo => _allows('editInfo');

  /// Removing is admin/owner only, and isn't delegated by a permission
  /// setting the way adding is (see removeMember's assertCanManage).
  bool get _canRemoveMembers => _isGroupAdmin;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.groupName;
    _avatarUrl = widget.groupAvatarUrl;
    _loadGroupDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetails() async {
    setState(() => _isLoading = true);
    try {
      final details = await _chatService.getConversationDetails(widget.chatId);
      final rawMembers = details['members'] ?? details['participants'] ?? [];
      setState(() {
        _members = List<dynamic>.from(rawMembers as Iterable);
        _permissions = Map<String, dynamic>.from(
          (details['permissions'] as Map?) ?? {},
        );
        _myRole = details['role']?.toString() ?? 'member';
        _avatarUrl =
            details['imageUrl'] as String? ??
            details['image'] as String? ??
            widget.groupAvatarUrl;
        _nameController.text =
            details['name'] as String? ??
            details['title'] as String? ??
            widget.groupName;
        _descriptionController.text =
            details['description'] as String? ??
            details['bio'] as String? ??
            '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack(AppLocalizations.of(context).groupProfileScreenFailedToLoad);
      }
    }
  }

  Future<void> _pickAndUploadGroupImage() async {
    try {
      final file = await pickImageFrom(ImageSource.gallery, imageQuality: 85);
      if (file == null) return;

      setState(() => _isUploadingImage = true);

      final mediaUrl = await uploadPickedImage(file);

      await _chatService.updateConversation(widget.chatId, imageUrl: mediaUrl);

      setState(() {
        _avatarUrl = mediaUrl;
        _isUploadingImage = false;
      });
      if (mounted) {
        _showSnack(AppLocalizations.of(context).groupProfileScreenImageUpdated);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context).groupProfileScreenUploadFailed('$e'),
        );
      }
    }
  }

  Future<void> _saveDescription() async {
    final desc = _descriptionController.text.trim();
    setState(() => _isSavingDescription = true);
    try {
      await _chatService.updateConversation(widget.chatId, description: desc);
      setState(() => _isSavingDescription = false);
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context).groupProfileScreenDescriptionUpdated,
        );
      }
    } catch (e) {
      setState(() => _isSavingDescription = false);
      if (mounted) {
        _showSnack(
          AppLocalizations.of(
            context,
          ).groupProfileScreenDescriptionUpdateFailed,
        );
      }
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == widget.groupName) return;
    setState(() => _isSaving = true);
    try {
      await _chatService.updateConversation(widget.chatId, name: name);
      setState(() => _isSaving = false);
      if (mounted) {
        _showSnack(AppLocalizations.of(context).groupProfileScreenNameUpdated);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context).groupProfileScreenNameUpdateFailed,
        );
      }
    }
  }

  Future<void> _pickMediaVisibility() async {
    final changed = await editChatMediaVisibility(
      context: context,
      chatId: widget.chatId,
      globalOn: context.read<SettingsProvider>().saveToPhotos,
    );
    if (changed && mounted) setState(() {});
  }

  Future<void> _leaveGroup() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupProfileScreenLeaveGroup),
        content: Text(l10n.groupProfileScreenLeaveGroupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.commonLeave),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _chatService.leaveConversation(widget.chatId);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context).groupProfileScreenLeaveFailed);
      }
    }
  }

  /// Ends the group for everyone. Owner-only, and the server enforces that
  /// independently — this only decides whether to offer it.
  Future<void> _deleteGroup() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupProfileScreenDeleteGroup),
        content: Text(l10n.groupProfileScreenDeleteGroupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.groupProfileScreenDeleteGroup),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final chats = context.read<ChatProvider>();
    final chat = chats.recentChats.firstWhere(
      (c) => c.conversationId == widget.chatId,
      orElse: () => chats.archivedChats.firstWhere(
        (c) => c.conversationId == widget.chatId,
        orElse: () => RecentChat(
          id: widget.chatId,
          chatType: 'group',
          createdAt: DateTime.now(),
          name: widget.groupName,
          imageUrl: widget.groupAvatarUrl ?? '',
          isPinned: false,
          isMuted: false,
          isArchived: false,
          unreadCount: 0,
        ),
      ),
    );

    try {
      await chats.deleteGroupChat(chat);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      _showSnack(l10n.groupProfileScreenGroupDeleted);
    } catch (e) {
      if (mounted) _showSnack(l10n.groupProfileScreenDeleteFailed);
    }
  }

  Future<void> _removeMember(String userId, String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupProfileScreenRemoveMemberTitle),
        content: Text(l10n.groupProfileScreenRemoveMemberBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.commonRemove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _chatService.removeMember(widget.chatId, userId);
      setState(
        () => _members.removeWhere((m) {
          final mId = m['userId']?['_id'] ?? m['userId'] ?? m['_id'];
          return mId == userId;
        }),
      );
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context).groupProfileScreenMemberRemoved(name),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context).groupProfileScreenRemoveMemberFailed,
        );
      }
    }
  }

  void _showAddMemberModal(BuildContext context, bool isDark) {
    final chats = context.read<ChatProvider>();
    showGroupAddMembersSheet(
      context: context,
      isDark: isDark,
      friends: contactCandidates(
        friends: context.read<FriendProvider>().friends,
        chats: [...chats.recentChats, ...chats.archivedChats],
        myId: chats.user?.id,
      ),
      members: _members,
      onAddMembers: _handleAddMembers,
    );
  }

  void _handleAddMembers(List<String> ids) async {
    try {
      await _chatService.addMembers(widget.chatId, ids);
      if (mounted) {
        _showSnack(
          AppLocalizations.of(
            context,
          ).groupProfileScreenMembersAdded(ids.length),
        );
      }
      _loadGroupDetails();
    } catch (e) {
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context).groupProfileScreenAddMembersFailed('$e'),
        );
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final surface = isDark ? const Color(0xFF070C17) : const Color(0xFFF6F7FB);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final l10n = AppLocalizations.of(context);

    final chat = _findRecentChat();
    final isMuted = chat?.isMuted ?? false;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.groupProfileScreenTitle,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: textColor),
            onPressed: () => _showGroupMenu(isDark, textColor),
          ),
        ],
      ),
      body: _isLoading
          ? GroupProfileLoadingSkeleton(isDark: isDark, primary: primary)
          : RefreshIndicator(
              onRefresh: _loadGroupDetails,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  GroupProfileHeader(
                    avatarUrl: _avatarUrl,
                    isUploadingImage: _isUploadingImage,
                    // Changing the photo is an edit-info action server-side.
                    onAvatarTap: _canEditInfo ? _pickAndUploadGroupImage : null,
                    name: _nameController.text,
                    memberCount: _members.length,
                    description: _descriptionController.text,
                    isDark: isDark,
                    textColor: textColor,
                    primary: primary,
                  ),
                  const SizedBox(height: 24),

                  GroupSettingsSection(
                    icon: Icons.groups_rounded,
                    title: l10n.commonMembers,
                    accent: primary,
                    isDark: isDark,
                    children: [
                      GroupSettingsRow(
                        icon: Icons.people_alt_rounded,
                        label: l10n.commonMembers,
                        value: '${_members.length}',
                        isDark: isDark,
                        onTap: () => _showMembersSheet(isDark, textColor),
                      ),
                      GroupSettingsRow(
                        icon: Icons.shield_rounded,
                        label: l10n.commonAdmins,
                        value: '${_adminCount()}',
                        isDark: isDark,
                        onTap: () => _showMembersSheet(
                          isDark,
                          textColor,
                          adminsOnly: true,
                        ),
                      ),
                      if (_canAddMembers)
                        GroupSettingsRow(
                          icon: Icons.person_add_alt_1_rounded,
                          label: l10n.groupProfileScreenInviteMembers,
                          isDark: isDark,
                          onTap: () => _showAddMemberModal(context, isDark),
                        ),
                    ],
                  ),

                  GroupSettingsSection(
                    icon: Icons.lock_rounded,
                    title: l10n.groupProfileScreenPrivacy,
                    accent: primary,
                    isDark: isDark,
                    children: [
                      GroupSettingsRow(
                        icon: Icons.verified_user_rounded,
                        label: l10n.commonPermissions,
                        isDark: isDark,
                        onTap: _openPermissions,
                      ),
                    ],
                  ),

                  GroupSettingsSection(
                    icon: Icons.chat_bubble_rounded,
                    title: l10n.commonChat,
                    accent: primary,
                    isDark: isDark,
                    children: [
                      if (_canEditInfo)
                        GroupSettingsRow(
                          icon: Icons.edit_rounded,
                          label: l10n.groupProfileScreenEditGroupInfo,
                          isDark: isDark,
                          onTap: () => _showEditInfoSheet(isDark, textColor),
                        ),
                      GroupSettingsRow(
                        icon: Icons.photo_library_outlined,
                        label: l10n.groupProfileScreenMediaVisibility,
                        value: mediaVisibilityLabel(
                          MediaVisibilityStore.instance.visibilityFor(
                            widget.chatId,
                          ),
                          globalOn: context
                              .watch<SettingsProvider>()
                              .saveToPhotos,
                        ),
                        isDark: isDark,
                        onTap: _pickMediaVisibility,
                      ),
                    ],
                  ),

                  GroupSettingsSection(
                    icon: Icons.notifications_rounded,
                    title: l10n.commonNotifications,
                    accent: primary,
                    isDark: isDark,
                    children: [
                      GroupSettingsRow(
                        icon: Icons.notifications_active_rounded,
                        label: l10n.groupProfileScreenMuteNotifications,
                        isDark: isDark,
                        onTap: null,
                        trailing: Switch(
                          value: isMuted,
                          activeThumbColor: Colors.white,
                          activeTrackColor: primary,
                          onChanged: chat == null
                              ? null
                              : (_) => context
                                    .read<ChatProvider>()
                                    .toggleMuteChat(chat),
                        ),
                      ),
                    ],
                  ),

                  GroupSettingsSection(
                    icon: Icons.warning_amber_rounded,
                    title: l10n.groupProfileScreenDangerZone,
                    accent: Colors.redAccent,
                    isDark: isDark,
                    children: [
                      GroupSettingsRow(
                        icon: Icons.logout_rounded,
                        label: l10n.groupProfileScreenLeaveGroup,
                        isDark: isDark,
                        isDestructive: true,
                        onTap: _leaveGroup,
                      ),
                      if (_isGroupOwner)
                        GroupSettingsRow(
                          icon: Icons.delete_forever_rounded,
                          label: l10n.groupProfileScreenDeleteGroup,
                          isDark: isDark,
                          isDestructive: true,
                          onTap: _deleteGroup,
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openPermissions() async {
    final updated = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupPermissionsScreen(
          chatId: widget.chatId,
          permissions: _permissions,
          canEdit: _isGroupAdmin,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _permissions = Map<String, dynamic>.from(updated));
    }
  }

  RecentChat? _findRecentChat() {
    for (final c in context.watch<ChatProvider>().recentChats) {
      if (c.conversationId == widget.chatId) return c;
    }
    return null;
  }

  int _adminCount() => _members.where((m) {
    final role = (m is Map ? m['role'] : null)?.toString() ?? 'member';
    return role == 'admin' || role == 'owner';
  }).length;

  // ─── Sheets ───────────────────────────────────────────────────────────────

  void _showGroupMenu(bool isDark, Color textColor) {
    showGroupProfileMenuSheet(
      context: context,
      isDark: isDark,
      textColor: textColor,
      onEditInfo: _canEditInfo
          ? () => _showEditInfoSheet(isDark, textColor)
          : null,
      onLeaveGroup: _leaveGroup,
      onDeleteGroup: _isGroupOwner ? _deleteGroup : null,
    );
  }

  /// Member list. Tapping a member opens their profile; admins can remove.
  void _showMembersSheet(
    bool isDark,
    Color textColor, {
    bool adminsOnly = false,
  }) {
    showGroupMembersSheet(
      context: context,
      members: _members,
      isDark: isDark,
      textColor: textColor,
      adminsOnly: adminsOnly,
      onRemoveMember: _canRemoveMembers ? _removeMember : null,
    );
  }

  /// Name + description editing, replacing the old inline edit toggles.
  void _showEditInfoSheet(bool isDark, Color textColor) {
    showGroupEditInfoSheet(
      context: context,
      isDark: isDark,
      textColor: textColor,
      nameController: _nameController,
      descriptionController: _descriptionController,
      isSavingName: _isSaving,
      isSavingDescription: _isSavingDescription,
      onSave: _saveGroupInfo,
    );
  }

  void _saveGroupInfo() async {
    await _saveName();
    await _saveDescription();
  }
}
