import 'package:flutter/material.dart';
import '../utils/call_duration.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:talkmos/core/router/app_router.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/providers/auth_provider.dart';
import 'package:talkmos/providers/chat_provider.dart';
import '../services/call_signaling/call_signaling_service.dart';
import '../../chats/services/chat_service/chat_service.dart';
import '../../chats/widgets/chats_search_bar.dart';
import '../../../models/call_model.dart';
import '../../../models/recent_chat.dart';
import '../utils/call_log_display.dart';
import '../../../core/utils/titlecase_function.dart';

enum _CallFilter { all, missed, incoming, outgoing }

class CallsScreen extends StatefulWidget {
  final CallSignalingService? signalingService;

  const CallsScreen({super.key, this.signalingService});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  late final CallSignalingService _signalingService;

  List<CallModel> _callLogs = [];
  _CallFilter _filter = _CallFilter.all;

  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _signalingService =
        widget.signalingService ?? context.read<CallSignalingService>();

    _signalingService.onCallHistoryReceived = _handleCallHistory;
    _signalingService.addListener(_onSignalingChanged);

    if (_signalingService.callHistory.isNotEmpty) {
      _handleCallHistory(_signalingService.callHistory);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCallLogs();
    });
  }

  void _onSignalingChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleCallHistory(List<Map<String, dynamic>> history) {
    if (!mounted) return;
    // One malformed entry shouldn't blank the whole list — parse each
    // independently and skip only the ones that fail.
    final logs = <CallModel>[];
    for (final item in history) {
      try {
        logs.add(CallModel.fromJson(item));
      } catch (e) {
        debugPrint('[CallsScreen] Skipping unparsable call log entry: $e');
      }
    }
    setState(() {
      _callLogs = logs;
    });
  }

  Future<void> _fetchCallLogs() async {
    if (!mounted) return;
    _signalingService.requestCallHistory();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '';
    return formatCallDuration(Duration(seconds: seconds));
  }

  String _formatTime(DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diffDays = now.difference(dt).inDays;

    if (diffDays == 0 && now.day == dt.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
      final ampm = dt.hour >= 12 ? l10n.callsScreenPm : l10n.callsScreenAm;
      return '$hour:$min $ampm';
    } else if (diffDays == 1 || (diffDays == 0 && now.day != dt.day)) {
      return l10n.commonYesterday;
    } else {
      final days = [
        l10n.callsScreenWeekdayMon,
        l10n.callsScreenWeekdayTue,
        l10n.callsScreenWeekdayWed,
        l10n.callsScreenWeekdayThu,
        l10n.callsScreenWeekdayFri,
        l10n.callsScreenWeekdaySat,
        l10n.callsScreenWeekdaySun,
      ];
      return days[dt.weekday - 1];
    }
  }

  String _getDateCategory(DateTime dt) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    if (dt.isAfter(todayStart)) {
      return 'Today';
    } else if (dt.isAfter(yesterdayStart)) {
      return 'Yesterday';
    } else {
      return 'This Week';
    }
  }

  String _emptyStateMessage(AppLocalizations l10n) {
    if (_searchQuery.trim().isNotEmpty) {
      return l10n.callsScreenNoSearchResults;
    }
    switch (_filter) {
      case _CallFilter.all:
        return l10n.callsScreenNoHistory;
      case _CallFilter.missed:
        return l10n.callsScreenNoMissedCalls;
      case _CallFilter.incoming:
        return l10n.callsScreenNoIncomingCalls;
      case _CallFilter.outgoing:
        return l10n.callsScreenNoOutgoingCalls;
    }
  }

  String _groupLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'Today':
        return l10n.commonToday;
      case 'Yesterday':
        return l10n.commonYesterday;
      default:
        return l10n.callsScreenOlder;
    }
  }

  bool _matchesFilter(CallModel log, String currentUserId, _CallFilter filter) {
    switch (filter) {
      case _CallFilter.all:
        return true;
      case _CallFilter.missed:
        return log.status == 'missed';
      case _CallFilter.incoming:
        return log.initiatorId != currentUserId && log.status != 'missed';
      case _CallFilter.outgoing:
        return log.initiatorId == currentUserId;
    }
  }

  Future<void> _redial(CallModel log, String currentUserId) async {
    final l10n = AppLocalizations.of(context);
    final myUser = context.read<AuthProvider>().user;
    final myName = myUser?.name ?? l10n.commonMe;

    final others = otherParticipants(log, currentUserId);
    final bool isGroup = isGroupCall(log);

    String targetId = '';
    String targetName = l10n.callsScreenDefaultUserName;
    String? targetAvatar;
    // Only set for the group branch, and only when `log.conversationId` came
    // back empty and had to be recovered from the local chat list instead.
    String? recoveredGroupConversationId;

    if (isGroup) {
      var conv = _conversationFor(log.conversationId);
      if (conv == null && (log.conversationId ?? '').isEmpty) {
        conv = _groupConversationForMembers(
          currentUserId,
          others.map((p) => p.userId),
        );
        recoveredGroupConversationId = conv?.conversationId;
      }
      targetName = callLogTitle(
        log: log,
        currentUserId: currentUserId,
        conversationTitle: conv?.title,
        unknownLabel: l10n.callsScreenDefaultUserName,
      );
      targetAvatar = conv?.avatarUrl;
      targetId = others.isNotEmpty ? others.first.userId : '';
    } else if (log.initiatorId == currentUserId) {
      if (others.isNotEmpty) {
        final other = others.first;
        targetId = other.userId;
        targetName = other.userDetails?.name ?? l10n.callsScreenDefaultUserName;
        targetAvatar = other.userDetails?.avatarUrl;
      }
    } else {
      targetId = log.initiatorId;
      targetName =
          log.initiatorDetails?.name ?? l10n.callsScreenDefaultUserName;
      targetAvatar = log.initiatorDetails?.avatarUrl;
    }

    final bool canPlace = isGroup
        ? (log.conversationId ?? '').isNotEmpty ||
              recoveredGroupConversationId != null
        : targetId.isNotEmpty;
    if (!canPlace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isGroup
                ? l10n.callsScreenCannotPlaceCallGroupNotFound
                : l10n.callsScreenCannotPlaceCallMissingDetails,
          ),
        ),
      );
      return;
    }

    try {
      final isVideo = log.type == 'video';
      String cid = log.conversationId ?? '';
      if (cid.isEmpty && isGroup) {
        cid = recoveredGroupConversationId ?? '';
      }
      if (cid.isEmpty && !isGroup) {
        try {
          cid = await ChatService().generateDirectChatId(targetId);
        } catch (e) {
          debugPrint('[CallsScreen] generateDirectChatId error: $e');
        }
      }

      if (cid.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.callsScreenCannotPlaceCallChatNotFound)),
        );
        return;
      }

      final outcome = await _signalingService.startOutgoingCall(
        chatId: cid,
        calleeId: targetId,
        calleeName: targetName,
        calleeAvatar: targetAvatar,
        initiatorName: myName,
        isVideo: isVideo,
      );

      if (!mounted) return;
      if (outcome == CallStartOutcome.invitedToActiveCall) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.commonAddedToCall(toTitleCase(targetName))),
          ),
        );
      }
      context.push(AppRoutes.activeCall);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.callsScreenFailedToStartCall(e.toString())),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_signalingService.onCallHistoryReceived == _handleCallHistory) {
      _signalingService.onCallHistoryReceived = null;
    }
    _signalingService.removeListener(_onSignalingChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  /// Same name resolution `_callLogTile` renders, pulled out so search
  /// filtering can't drift from what the row actually displays.
  String _callLogName(CallModel log, String currentUserId) {
    final l10n = AppLocalizations.of(context);
    final isGroup = isGroupCall(log);
    final conv = isGroup ? _conversationFor(log.conversationId) : null;
    return callLogTitle(
      log: log,
      currentUserId: currentUserId,
      conversationTitle: conv?.title,
      unknownLabel: l10n.commonUnknown,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.id ?? '';

    final query = _searchQuery.trim().toLowerCase();
    final filteredLogs = _callLogs
        .where((l) => _matchesFilter(l, currentUserId, _filter))
        .where(
          (l) =>
              query.isEmpty ||
              _callLogName(l, currentUserId).toLowerCase().contains(query),
        )
        .toList();

    final Map<String, List<CallModel>> groupedLogs = {
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    for (final log in filteredLogs) {
      final category = _getDateCategory(log.startedAt);
      if (category == 'Today') {
        groupedLogs['Today']!.add(log);
      } else if (category == 'Yesterday') {
        groupedLogs['Yesterday']!.add(log);
      } else {
        groupedLogs['Older']!.add(log);
      }
    }

    final hasAnyLogs = groupedLogs.values.any((list) => list.isNotEmpty);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: _isSearching
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF000000),
                ),
                onPressed: _stopSearch,
              )
            : null,
        title: _isSearching
            ? ChatsSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                isDark: isDark,
                showClear: _searchQuery.isNotEmpty,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
              )
            : Text(
                l10n.commonCalls,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF000000),
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
        actions: _isSearching
            ? const []
            : [
                IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                    size: 24,
                  ),
                  onPressed: _startSearch,
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                    size: 24,
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetchCallLogs,
          color: Theme.of(context).primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSegmentedFilterTabs(isDark),
                ),
                const SizedBox(height: 12),
                if (!hasAnyLogs)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        _emptyStateMessage(l10n),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  for (final entry in groupedLogs.entries)
                    if (entry.value.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          _groupLabel(entry.key, l10n),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entry.value.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 76,
                          endIndent: 0,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (_, i) {
                          return _callLogTile(
                            entry.value[i],
                            isDark,
                            currentUserId,
                          );
                        },
                      ),
                    ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedFilterTabs(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _segmentedTab(_CallFilter.all, l10n.callsScreenFilterAll, isDark),
          const SizedBox(width: 8),
          _segmentedTab(
            _CallFilter.missed,
            l10n.callsScreenFilterMissed,
            isDark,
          ),
          const SizedBox(width: 8),
          _segmentedTab(
            _CallFilter.incoming,
            l10n.callsScreenFilterIncoming,
            isDark,
          ),
          const SizedBox(width: 8),
          _segmentedTab(
            _CallFilter.outgoing,
            l10n.callsScreenFilterOutgoing,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _segmentedTab(_CallFilter filter, String label, bool isDark) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isDark ? const Color(0xFF000814) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF374151)),
            ),
          ),
        ),
      ),
    );
  }

  RecentChat? _conversationFor(String? conversationId) {
    if (conversationId == null || conversationId.isEmpty) return null;
    for (final c in context.read<ChatProvider>().recentChats) {
      if (c.conversationId == conversationId) return c;
    }
    return null;
  }

  RecentChat? _groupConversationForMembers(
    String currentUserId,
    Iterable<String> otherUserIds,
  ) {
    final wanted = {currentUserId, ...otherUserIds}
      ..removeWhere((id) => id.isEmpty);
    if (wanted.length < 2) return null;
    for (final c in context.read<ChatProvider>().recentChats) {
      if (c.chatType != 'group') continue;
      final members = c.members.map((m) => m.id).toSet();
      if (members.containsAll(wanted) && wanted.containsAll(members)) {
        return c;
      }
    }
    return null;
  }

  Widget _callLogTile(CallModel log, bool isDark, String currentUserId) {
    final isOutgoing = log.initiatorId == currentUserId;
    final isMissed = log.status == 'missed';

    final bool isGroup = isGroupCall(log);
    final conv = isGroup ? _conversationFor(log.conversationId) : null;

    final name = _callLogName(log, currentUserId);
    final avatarUrl = callLogAvatarUrl(
      log: log,
      currentUserId: currentUserId,
      conversationAvatarUrl: conv?.avatarUrl,
    );

    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final Color subTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final isVideoCall = log.type == 'video';
    final titleColor = isMissed && !isOutgoing
        ? const Color(0xFFEF4444)
        : (isDark ? Colors.white : const Color(0xFF000000));

    final IconData statusIcon = isOutgoing
        ? Icons.call_made_rounded
        : (isMissed ? Icons.call_missed_rounded : Icons.call_received_rounded);

    final Color iconColor = isMissed
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);

    final durationText = log.durationSeconds != null && log.durationSeconds! > 0
        ? ' (${_formatDuration(log.durationSeconds)})'
        : '';

    return InkWell(
      onTap: () => _redial(log, currentUserId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AvatarCircle(
              imageUrl: avatarUrl,
              radius: 24,
              backgroundColor: isGroup
                  ? Color(0xFF8B5CF6).withValues(alpha: 0.15)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.12),
              fallback: isGroup
                  ? Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 22,
                    )
                  : Text(
                      initials,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(statusIcon, size: 15, color: iconColor),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${_formatTime(log.startedAt)}$durationText',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: subTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isVideoCall ? Icons.videocam_rounded : Icons.call_rounded,
                size: 22,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () => _redial(log, currentUserId),
              splashRadius: 24,
            ),
          ],
        ),
      ),
    );
  }
}
