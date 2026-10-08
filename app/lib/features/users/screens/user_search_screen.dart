import 'dart:async';
import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../../models/user_model.dart';
import '../services/user_search_service.dart';
import 'user_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _service = UserSearchService();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _error = '';

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
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = '';
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(val.trim()),
    );
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final results = await _service.search(q);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF000000),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.userSearchScreenTitle,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF000000),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full-width Search Bar
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF000814)
                      : const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: (val) {
                    setState(() {});
                    _onChanged(val);
                  },
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF000000),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 46,
                      minHeight: 44,
                    ),
                    hintText: l10n.userSearchScreenSearchHint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    isDense: false,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _controller.clear();
                              FocusScope.of(context).unfocus();
                              _onChanged('');
                            },
                            child: const Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Talkmos ID Banner Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.userSearchScreenBannerTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.userSearchScreenBannerSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_loading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                )
              else if (_error.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                )
              else if (_controller.text.trim().isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.userSearchScreenEmptyPrompt,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_results.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      l10n.userSearchScreenNoResults,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else ...[
                Text(
                  l10n.userSearchScreenResultsHeader,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF000814) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (_, i) =>
                        _UserResultTile(user: _results[i], isDark: isDark),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;

  const _UserResultTile({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name =
        user['name']?.toString() ?? l10n.userSearchScreenDefaultUserName;
    final username = user['username']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final isVerified = user['isVerified'] == true;
    final peerId = user['_id']?.toString() ?? user['id']?.toString() ?? '';

    final authProvider = context.watch<AuthProvider>();
    final friendProvider = context.watch<FriendProvider>();

    final myId = authProvider.user?.id ?? '';
    final isMe = myId.isNotEmpty && myId == peerId;
    final status = friendProvider.getFriendshipStatus(peerId);

    // A private account is a name to send a request to, nothing more, until
    // they accept — the server withholds the details either way.
    final canOpenProfile =
        isMe ||
        user['isPublic'] != false ||
        status == FriendshipStatus.accepted;

    return InkWell(
      onTap: () {
        if (!canOpenProfile) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userSearchScreenPrivateAccount)),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(user: UserModel.fromJson(user)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        toTitleCase(name),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF000000),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 15,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    username.isNotEmpty ? '@$username' : email,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildActionButton(context, peerId, isMe, status, friendProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String peerId,
    bool isMe,
    FriendshipStatus status,
    FriendProvider friendProvider,
  ) {
    final l10n = AppLocalizations.of(context);
    if (isMe) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF000E23) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          l10n.commonYou,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      );
    }

    switch (status) {
      case FriendshipStatus.accepted:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.userSearchScreenFriendStatus,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );

      case FriendshipStatus.sent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000E23) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF64748B),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.userSearchScreenPendingStatus,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );

      case FriendshipStatus.received:
        return GestureDetector(
          onTap: () {
            final req = friendProvider.pendingIncomingRequests.firstWhere(
              (r) => (r['sender'] is Map) && r['sender']['_id'] == peerId,
              orElse: () => <String, dynamic>{},
            );
            final reqId = req['_id']?.toString();
            if (reqId != null) {
              friendProvider.acceptRequest(reqId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.userSearchScreenRequestAccepted)),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.commonAccept,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );

      case FriendshipStatus.none:
      default:
        return GestureDetector(
          onTap: () async {
            if (peerId.isNotEmpty) {
              try {
                await friendProvider.sendRequest(peerId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.userSearchScreenRequestSent)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.userSearchScreenSendRequestError(e.toString()),
                      ),
                    ),
                  );
                }
              }
            }
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
          ),
        );
    }
  }
}
