import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../users/utils/contact_search.dart';
import '../../../models/friend_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../services/chat_service/chat_service.dart';
import '../utils/contact_candidates.dart';
import '../widgets/friend_avatar.dart';
import '../widgets/group_member_list_widgets.dart';
import '../widgets/group_photo_picker.dart';
import '../widgets/input_field_widgets.dart';
import '../widgets/selected_members_strip.dart';
import '../widgets/wizard_back_button.dart';
import '../widgets/wizard_step_header.dart';
import 'chat_screen/chat_screen.dart';

/// Three-step group creation: details → members → review.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  static const int _totalSteps = 3;
  static const int _nameMaxLength = 50;
  static const int _descriptionMaxLength = 200;

  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final _chatService = ChatService();

  int _step = 0;
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  bool _isCreating = false;

  XFile? _pickedPhoto;
  String _photoUrl = '';
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FriendProvider>().loadFriendsAndRequests();
      // Non-friend chat partners are selectable too, so the chat list has to
      // be there even when the user came straight here without opening it.
      final chats = context.read<ChatProvider>();
      if (chats.recentChats.isEmpty) chats.loadRecentChats();
    });
    // Redraw counters and the Next button's enabled state as the user types.
    _groupNameController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _groupNameController.removeListener(_onTextChanged);
    _descriptionController.removeListener(_onTextChanged);
    _groupNameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Navigation between steps ─────────────────────────────────────────────

  void _next() {
    if (_step < _totalSteps - 1) {
      FocusScope.of(context).unfocus();
      setState(() => _step++);
    } else {
      _createGroup();
    }
  }

  /// Back steps through the wizard before leaving the screen entirely.
  Future<bool> _handleBack() async {
    if (_step > 0) {
      FocusScope.of(context).unfocus();
      setState(() => _step--);
      return false;
    }
    return true;
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _groupNameController.text.trim().isNotEmpty &&
            !_isUploadingPhoto;
      case 1:
        return _selectedIds.isNotEmpty;
      default:
        return !_isCreating;
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    try {
      final file = await pickImageFrom(ImageSource.gallery, imageQuality: 85);
      if (file == null) return;

      setState(() {
        _pickedPhoto = file;
        _isUploadingPhoto = true;
      });

      final url = await uploadPickedImage(file);
      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      // Drop the preview so the UI doesn't imply an upload that didn't land.
      if (mounted) setState(() => _pickedPhoto = null);
      _showSnack(
        AppLocalizations.of(
          context,
        ).createGroupScreenPhotoUploadFailed(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  Future<void> _createGroup() async {
    final l10n = AppLocalizations.of(context);
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      _showSnack(l10n.createGroupScreenEnterName);
      return;
    }
    if (_selectedIds.isEmpty) {
      _showSnack(l10n.createGroupScreenSelectAtLeastOneMember);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final group = await _chatService.createConversation(
        type: 'group',
        name: name,
        participantIds: _selectedIds.toList(),
        description: _descriptionController.text.trim(),
        imageUrl: _photoUrl,
      );
      if (!mounted) return;

      AnalyticsService.logEvent(
        'group_created',
        parameters: {'member_count': _selectedIds.length},
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: group['_id'] as String,
            chatType: 'group',
            activeUser: UserModel(id: '', name: name, avatarUrl: _photoUrl),
          ),
        ),
      );
    } catch (e) {
      _showSnack(l10n.createGroupScreenCreateFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF060B18) : const Color(0xFFF7F8FC);
    final textColor = isDark ? Colors.white : const Color(0xFF0B1120);

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        WizardBackButton(
                          isDark: isDark,
                          onTap: () async {
                            if (await _handleBack() && mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        Text(
                          l10n.createGroupScreenTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    WizardStepHeader(
                      currentStep: _step,
                      totalSteps: _totalSteps,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: switch (_step) {
                  0 => _buildDetailsStep(isDark, textColor),
                  1 => _buildMembersStep(isDark, textColor),
                  _ => _buildReviewStep(isDark, textColor),
                },
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: WizardPrimaryButton(
                  label: _step == _totalSteps - 1
                      ? l10n.createGroupScreenTitle
                      : l10n.createGroupScreenNext,
                  trailingIcon: _step == _totalSteps - 1
                      ? Icons.check_rounded
                      : Icons.chevron_right_rounded,
                  busy: _isCreating,
                  onPressed: _canAdvance ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 1: details ──────────────────────────────────────────────────────

  Widget _buildDetailsStep(bool isDark, Color textColor) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GroupPhotoPicker(
              pickedPhoto: _pickedPhoto,
              isUploadingPhoto: _isUploadingPhoto,
              isDark: isDark,
              primary: primary,
              onTap: _isUploadingPhoto ? null : _pickPhoto,
            ),
          ),
          const SizedBox(height: 28),

          FieldLabel(l10n.createGroupScreenNameLabel, textColor: textColor),
          const SizedBox(height: 10),
          InputShell(
            isDark: isDark,
            child: Row(
              children: [
                Icon(Icons.groups_rounded, color: primary, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    maxLength: _nameMaxLength,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(fontSize: 16, color: textColor),
                    decoration: InputDecoration(
                      hintText: l10n.createGroupScreenNameHint,
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF9AA3B2),
                      ),
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                ),
                Text(
                  '${_groupNameController.text.characters.length}/$_nameMaxLength',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              FieldLabel(
                l10n.createGroupScreenDescriptionLabel,
                textColor: textColor,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.createGroupScreenOptional,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InputShell(
            isDark: isDark,
            height: 176,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.description_rounded,
                          color: primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _descriptionController,
                          maxLength: _descriptionMaxLength,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(fontSize: 16, color: textColor),
                          decoration: InputDecoration(
                            hintText: l10n.createGroupScreenDescriptionHint,
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF9AA3B2),
                            ),
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${_descriptionController.text.characters.length}/$_descriptionMaxLength',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.createGroupScreenDescriptionHelper,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  List<FriendModel> _candidates() {
    final chats = context.watch<ChatProvider>();
    return contactCandidates(
      friends: context.watch<FriendProvider>().friends,
      chats: [...chats.recentChats, ...chats.archivedChats],
      myId: chats.user?.id,
    );
  }

  // ─── Step 2: members ──────────────────────────────────────────────────────

  Widget _buildMembersStep(bool isDark, Color textColor) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final all = _candidates();
    final query = _searchQuery.toLowerCase();
    final visible = query.isEmpty
        ? all
        : all
              .where(
                (f) => ContactSearch.matches(
                  query: query,
                  name: f.name,
                  username: f.username,
                  phone: f.phone,
                  email: f.email,
                ),
              )
              .toList();
    final selected = all.where((f) => _selectedIds.contains(f.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.createGroupScreenSelectMembers,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.createGroupScreenSelectMembersSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.createGroupScreenSelectedCount(_selectedIds.length),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: InputShell(
            isDark: isDark,
            filled: true,
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: TextStyle(fontSize: 15, color: textColor),
                    decoration: InputDecoration(
                      hintText: l10n.createGroupScreenSearchMembersHint,
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF9AA3B2),
                      ),
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: SelectedMembersStrip(
              selected: selected,
              isDark: isDark,
              textColor: textColor,
              primary: primary,
              onRemove: _toggleSelect,
            ),
          ),

        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? GroupMembersEmptyState(
                  isDark: isDark,
                  searchQuery: _searchQuery,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: visible.length,
                  itemBuilder: (_, i) => GroupMemberTile(
                    friend: visible[i],
                    isSelected: _selectedIds.contains(visible[i].id),
                    isDark: isDark,
                    textColor: textColor,
                    primary: primary,
                    onTap: () => _toggleSelect(visible[i].id),
                  ),
                ),
        ),
      ],
    );
  }

  // ─── Step 3: review ───────────────────────────────────────────────────────

  Widget _buildReviewStep(bool isDark, Color textColor) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final selected = _candidates()
        .where((f) => _selectedIds.contains(f.id))
        .toList();
    final description = _descriptionController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                GroupPhotoAvatar(
                  pickedPhoto: _pickedPhoto,
                  size: 104,
                  isDark: isDark,
                  primary: primary,
                ),
                const SizedBox(height: 14),
                Text(
                  toTitleCase(_groupNameController.text.trim()),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),
          Text(
            l10n.createGroupScreenMemberCount(selected.length),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          for (final f in selected)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  FriendAvatar(friend: f, radius: 22, primary: primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      toTitleCase(f.name),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    onPressed: () => _toggleSelect(f.id),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
