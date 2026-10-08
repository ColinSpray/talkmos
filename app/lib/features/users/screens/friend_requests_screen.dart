import 'dart:async';
import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../../core/services/analytics_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  final int initialTabIndex;

  const FriendRequestsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  int _selectedTab = 0; // 0 = Received, 1 = Sent

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().loadFriendsAndRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<FriendProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final receivedList = state.pendingIncomingRequests;
    final sentList = state.pendingOutgoingRequests;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 24,
            color: isDark ? Colors.white : const Color(0xFF000000),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.friendRequestsScreenTitle,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF000000),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<FriendProvider>().loadFriendsAndRequests(),
                color: Theme.of(context).primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Segment Tabs: Received | Sent
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? Theme.of(context).primaryColor
                                      : (isDark
                                            ? const Color(0xFF000814)
                                            : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.friendRequestsScreenReceivedTab,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _selectedTab == 0
                                            ? Colors.white
                                            : (isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedTab == 0
                                            ? Colors.white.withValues(
                                                alpha: 0.25,
                                              )
                                            : const Color(0xFFCBD5E1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${receivedList.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedTab == 0
                                              ? Colors.white
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? Theme.of(context).primaryColor
                                      : (isDark
                                            ? const Color(0xFF000814)
                                            : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.friendRequestsScreenSentTab,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _selectedTab == 1
                                            ? Colors.white
                                            : (isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedTab == 1
                                            ? Colors.white.withValues(
                                                alpha: 0.25,
                                              )
                                            : const Color(0xFFCBD5E1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${sentList.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedTab == 1
                                              ? Colors.white
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section title
                      Text(
                        _selectedTab == 1
                            ? l10n.friendRequestsScreenSectionSent
                            : l10n.friendRequestsScreenSectionReceived,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_selectedTab == 0 && receivedList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              l10n.friendRequestsScreenNoReceived,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else if (_selectedTab == 1 && sentList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              l10n.friendRequestsScreenNoSent,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedTab == 0
                              ? receivedList.length
                              : sentList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            if (_selectedTab == 0) {
                              final item = receivedList[index];
                              final sender = item['sender'] is Map
                                  ? item['sender']
                                  : item;
                              final name =
                                  sender['name']?.toString() ??
                                  l10n.friendRequestsScreenDefaultUserName;
                              final username =
                                  sender['username']?.toString() ?? '';
                              final reqId = item['_id']?.toString() ?? '';
                              return _requestCard(
                                reqId: reqId,
                                name: name,
                                username: username.isNotEmpty
                                    ? '@$username'
                                    : '',
                                isReceived: true,
                                isDark: isDark,
                                message: item['message']?.toString() ?? '',
                                isNearby: item['source'] == 'nearby',
                              );
                            } else {
                              final item = sentList[index];
                              final receiver = item['receiver'] is Map
                                  ? item['receiver']
                                  : item;
                              final name =
                                  receiver['name']?.toString() ??
                                  l10n.friendRequestsScreenDefaultUserName;
                              final username =
                                  receiver['username']?.toString() ?? '';
                              final reqId = item['_id']?.toString() ?? '';
                              return _requestCard(
                                reqId: reqId,
                                name: name,
                                username: username.isNotEmpty
                                    ? '@$username'
                                    : '',
                                isReceived: false,
                                isDark: isDark,
                                message: item['message']?.toString() ?? '',
                                isNearby: item['source'] == 'nearby',
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Shield Privacy Banner matching Image 4
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.friendRequestsScreenPrivacyHint,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.friendRequestsScreenLearnMorePrivacy,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
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

  Future<void> _acceptRequest(String reqId) async {
    final chatProvider = context.read<ChatProvider>();
    try {
      await context.read<FriendProvider>().acceptRequest(reqId);
      AnalyticsService.logEvent('friend_request_accepted');
      unawaited(chatProvider.loadRecentChats(force: true));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.friendRequestsScreenAcceptError(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _requestCard({
    required String reqId,
    required String name,
    required String username,
    required bool isReceived,
    required bool isDark,
    String message = '',
    bool isNearby = false,
  }) {
    final friendProvider = context.read<FriendProvider>();
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000814) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toTitleCase(name),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        username,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isReceived)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (reqId.isNotEmpty)
                          friendProvider.rejectRequest(reqId);
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF000E23)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (reqId.isNotEmpty) _acceptRequest(reqId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.commonAccept,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (reqId.isNotEmpty)
                          friendProvider.rejectRequest(reqId);
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF000E23)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        l10n.friendRequestsScreenPending,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF000E23)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNearby) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 13,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Sent from Nearby',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
