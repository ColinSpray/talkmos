import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/analytics_service.dart';
import '../services/phone_contacts_service.dart';
import '../utils/contact_search.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/models/friend_model.dart';
import 'package:talkmos/models/user_model.dart';
import '../../chats/services/chat_service/chat_service.dart';
import 'package:talkmos/providers/providers.dart';
import '../../chats/screens/chat_screen/chat_screen.dart';
import '../../chats/screens/create_group_screen.dart';
import 'user_search_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key});

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<PhoneContact> _phoneContacts = [];
  bool _loadingPhoneContacts = false;
  bool _contactsPermissionDenied = false;
  bool _contactsRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FriendProvider>().loadFriendsAndRequests();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final friendProvider = context.watch<FriendProvider>();
    final friends = friendProvider.friends;
    final isLoading = friendProvider.isLoading;

    final filteredFriends = _searchQuery.isEmpty
        ? friends
        : friends
              .where(
                (f) => ContactSearch.matches(
                  query: _searchQuery,
                  name: f.name,
                  username: f.username,
                  phone: f.phone,
                  email: f.email,
                ),
              )
              .toList();

    final bgColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchQuery = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        titleSpacing: _isSearching ? 0 : 0,
        title: _isSearching
            ? Container(
                height: 42,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF000814)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.selectContactScreenSearchHint,
                    hintStyle: TextStyle(color: subtextColor, fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: subtextColor,
                      size: 20,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: Icon(
                              Icons.cancel_rounded,
                              color: subtextColor,
                              size: 18,
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 4,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectContactScreenTitle,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading
                        ? l10n.selectContactScreenLoadingContacts
                        : l10n.selectContactScreenContactCount(friends.length),
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
        actions: _isSearching
            ? null
            : [
                IconButton(
                  icon: Icon(Icons.search_rounded, color: textColor),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                    AnalyticsService.logEvent('select_contact_search_opened');
                    if (!_contactsRequested) {
                      _loadPhoneContacts();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: textColor),
                  onPressed: () {},
                ),
              ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Upper 3 Options ListTiles (WhatsApp Style) ─────────────────
              _buildUpperOptionTile(
                isDark: isDark,
                icon: Icons.group_add_rounded,
                title: l10n.selectContactScreenNewGroup,
                subtitle: l10n.selectContactScreenNewGroupSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen(),
                    ),
                  );
                },
              ),
              _buildUpperOptionTile(
                isDark: isDark,
                icon: Icons.person_add_rounded,
                title: l10n.selectContactScreenNewContact,
                subtitle: l10n.selectContactScreenNewContactSubtitle,
                trailingIcon: Icons.qr_code_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserSearchScreen()),
                  );
                },
              ),

              const SizedBox(height: 6),

              // ── Contacts Section Header ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 4,
                ),
                child: Text(
                  l10n.selectContactScreenContactsOnTalkmos,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: subtextColor,
                  ),
                ),
              ),

              // ── Contacts List ──────────────────────────────────────────────
              if (isLoading)
                Skeletonizer(
                  enabled: true,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    itemBuilder: (_, __) => _buildContactSkeletonTile(isDark),
                  ),
                )
              else if (filteredFriends.isEmpty)
                _buildEmptyState(context, isDark)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = filteredFriends[index];
                    return _buildContactTile(context, friend, isDark);
                  },
                ),

              const SizedBox(height: 24),
              _buildPhoneContactsSection(isDark, textColor, subtextColor),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Phone book ───────────────────────────────────────────────────────────

  Future<void> _loadPhoneContacts() async {
    setState(() {
      _loadingPhoneContacts = true;
      _contactsRequested = true;
    });
    final result = await PhoneContactsService.load();
    if (!mounted) return;
    setState(() {
      _phoneContacts = result.contacts;
      _contactsPermissionDenied = result.permissionDenied;
      _loadingPhoneContacts = false;
    });
    AnalyticsService.logEvent(
      'phone_contacts_requested',
      parameters: {
        'permission_denied': result.permissionDenied.toString(),
        'contact_count': result.contacts.length,
      },
    );
  }

  List<PhoneContact> get _visiblePhoneContacts {
    if (_searchQuery.isEmpty) return _phoneContacts;
    final q = _searchQuery.toLowerCase();
    return _phoneContacts
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(q) ||
              c.phone
                  .replaceAll(RegExp(r'[^0-9]'), '')
                  .contains(q.replaceAll(RegExp(r'[^0-9]'), '')),
        )
        .toList();
  }

  Widget _buildPhoneContactsSection(
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;

    if (!_contactsRequested) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          onPressed: _loadPhoneContacts,
          icon: Icon(Icons.contacts_rounded, color: primary),
          label: Text(
            l10n.selectContactScreenFindContactsOnTalkmos,
            style: TextStyle(color: primary, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primary.withValues(alpha: 0.4)),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    if (_loadingPhoneContacts) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _phoneContactsHeader(subtextColor),
          Skeletonizer(
            enabled: true,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (_, __) =>
                  _buildContactSkeletonTile(isDark, withAction: true),
            ),
          ),
        ],
      );
    }

    if (_contactsPermissionDenied) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectContactScreenPermissionDeniedMessage,
              style: TextStyle(fontSize: 13, color: subtextColor),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadPhoneContacts,
              child: Text(l10n.selectContactScreenTryAgain),
            ),
          ],
        ),
      );
    }

    final contacts = _visiblePhoneContacts;
    if (contacts.isEmpty) {
      return _buildPhoneContactsEmptyState(isDark, textColor, subtextColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _phoneContactsHeader(subtextColor),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          itemBuilder: (_, i) => _buildPhoneContactTile(
            contacts[i],
            isDark,
            textColor,
            subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneContactsEmptyState(
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final searching = _searchQuery.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching
                  ? Icons.search_off_rounded
                  : Icons.contact_phone_outlined,
              size: 38,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searching
                ? l10n.selectContactScreenNoMatchingContacts
                : l10n.selectContactScreenNothingToShowYet,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? l10n.selectContactScreenNoPhoneContactsMatch(_searchQuery)
                : l10n.selectContactScreenIndianNumbersOnly,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45, color: subtextColor),
          ),
          const SizedBox(height: 20),
          if (searching)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(l10n.selectContactScreenClearSearch),
              style: TextButton.styleFrom(foregroundColor: primary),
            )
          else
            OutlinedButton.icon(
              onPressed: _loadPhoneContacts,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.selectContactScreenRefreshContacts),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _phoneContactsHeader(Color subtextColor) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Text(
      AppLocalizations.of(context).selectContactScreenFromYourContacts,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: subtextColor,
      ),
    ),
  );

  Widget _buildPhoneContactTile(
    PhoneContact contact,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final primary = Theme.of(context).primaryColor;
    final action = contact.action;

    // Only a public account (or an existing friendship) can be opened straight
    // into a chat; everything else needs a request or an invite first.
    final canOpenChat =
        action == ContactAction.chat || action == ContactAction.friends;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: canOpenChat ? () => _openChatWith(contact) : null,
      leading: AvatarCircle(
        imageUrl: contact.avatarUrl,
        radius: 22,
        backgroundColor: primary.withValues(alpha: 0.12),
        fallback: Text(
          contact.displayName.isNotEmpty
              ? contact.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(color: primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        toTitleCase(contact.displayName),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        contact.isOnTalkmos && (contact.username ?? '').isNotEmpty
            ? '@${contact.username}'
            : contact.phone,
        style: TextStyle(fontSize: 13, color: subtextColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _buildContactAction(contact, action, primary, subtextColor),
    );
  }

  Widget _buildContactAction(
    PhoneContact contact,
    ContactAction action,
    Color primary,
    Color subtextColor,
  ) {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case ContactAction.invite:
        return TextButton(
          onPressed: () => _invite(contact),
          style: TextButton.styleFrom(foregroundColor: primary),
          child: Text(
            l10n.selectContactScreenInvite,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      case ContactAction.addFriend:
        return IconButton(
          tooltip: l10n.selectContactScreenAddFriendTooltip,
          icon: Icon(Icons.person_add_alt_1_rounded, color: primary),
          onPressed: () => _addFriend(contact),
        );
      case ContactAction.requestSent:
        return Text(
          l10n.selectContactScreenRequested,
          style: TextStyle(fontSize: 13, color: subtextColor),
        );
      case ContactAction.requestReceived:
        return Text(
          l10n.selectContactScreenWantsToConnect,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: primary,
          ),
        );
      case ContactAction.chat:
      case ContactAction.friends:
        return Icon(Icons.chat_bubble_rounded, color: primary, size: 20);
    }
  }

  Future<void> _openChatWith(PhoneContact contact) async {
    final user = UserModel(
      id: contact.userId!,
      name: contact.displayName,
      username: contact.username ?? '',
      avatarUrl: contact.avatarUrl ?? '',
    );
    try {
      final chatId = await ChatService().generateDirectChatId(contact.userId!);
      if (!mounted) return;
      AnalyticsService.logEvent(
        'chat_opened',
        parameters: {'source': 'phone_contacts'},
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(activeUser: user, chatId: chatId, chatType: 'direct'),
        ),
      );
    } catch (e) {
      _toast(
        AppLocalizations.of(context).selectContactScreenCouldNotOpenChat('$e'),
      );
    }
  }

  Future<void> _addFriend(PhoneContact contact) async {
    final l10n = AppLocalizations.of(context);
    final index = _phoneContacts.indexOf(contact);
    // Optimistic, rolled back below if the request fails.
    if (index != -1) {
      setState(
        () => _phoneContacts[index] = contact.copyWith(
          friendship: 'request_sent',
        ),
      );
    }
    try {
      await context.read<FriendProvider>().sendRequest(contact.userId!);
      AnalyticsService.logEvent(
        'friend_request_sent',
        parameters: {'source': 'phone_contacts'},
      );
      _toast(l10n.selectContactScreenFriendRequestSent);
    } catch (e) {
      if (index != -1 && mounted) {
        setState(() => _phoneContacts[index] = contact);
      }
      _toast(l10n.selectContactScreenCouldNotSendRequest('$e'));
    }
  }

  Future<void> _invite(PhoneContact contact) async {
    final l10n = AppLocalizations.of(context);
    final message = Uri.encodeComponent(l10n.selectContactScreenInviteMessage);
    final uri = Uri.parse('sms:${contact.phone}?body=$message');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) {
        AnalyticsService.logEvent('contact_invited');
      } else {
        _toast(l10n.selectContactScreenNoMessagingApp);
      }
    } catch (e) {
      _toast(l10n.selectContactScreenCouldNotOpenMessagingApp);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildUpperOptionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? trailingIcon,
    required VoidCallback onTap,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minVerticalPadding: 2,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subtextColor),
      ),
      trailing: trailingIcon != null
          ? Icon(trailingIcon, color: subtextColor, size: 18)
          : null,
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    FriendModel friend,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minVerticalPadding: 2,
      onTap: () {
        AnalyticsService.logEvent(
          'chat_opened',
          parameters: {'source': 'friends_list'},
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              activeUser: friend.toUserModel(),
              chatId: friend.chatId ?? '',
              chatType: 'direct',
            ),
          ),
        );
      },
      leading: AvatarCircle(
        imageUrl: friend.avatarUrl,
        radius: 20,
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
        fallback: Text(
          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              toTitleCase(friend.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (friend.isVerified) ...[const SizedBox(width: 4)],
        ],
      ),
      subtitle: Text(
        friend.status != null && friend.status!.isNotEmpty
            ? friend.status!
            : (friend.username != null && friend.username!.isNotEmpty
                  ? '@${friend.username}'
                  : AppLocalizations.of(
                      context,
                    ).selectContactScreenDefaultStatus),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: subtextColor),
      ),
    );
  }

  Widget _buildContactSkeletonTile(bool isDark, {bool withAction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Bone.circle(size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Bone.text(width: 140, fontSize: 15),
                SizedBox(height: 6),
                Bone.text(width: 100, fontSize: 12),
              ],
            ),
          ),
          // Phone-contact rows carry an Invite / Add-friend control, so the
          // placeholder reserves that space too.
          if (withAction) ...[
            const SizedBox(width: 12),
            const Bone(width: 58, height: 22),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contacts_rounded,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? l10n.selectContactScreenNoMatchingContacts
                : l10n.selectContactScreenNoContactsFound,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? l10n.selectContactScreenNoFriendsFoundMatching(_searchQuery)
                : l10n.selectContactScreenAddFriendsToStartChatting,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              );
            },
            icon: const Icon(Icons.person_search_rounded, size: 18),
            label: Text(l10n.selectContactScreenFindContacts),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
