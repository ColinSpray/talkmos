import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/services/media_cache_service.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final String peerName;
  final String? peerAvatarUrl;
  final bool isDark;
  final bool isOnline;
  final bool isTyping;

  /// Null while they are online, and when their privacy setting hides it.
  final DateTime? lastSeenAt;
  final VoidCallback onBack;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  const ChatHeader({
    super.key,
    required this.peerName,
    this.peerAvatarUrl,
    required this.isDark,
    this.isOnline = false,
    this.isTyping = false,
    this.lastSeenAt,
    required this.onBack,
    this.actions,
    this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  String? _subtitle(AppLocalizations l10n) {
    if (isOnline) return l10n.chatHeaderOnline;
    final at = lastSeenAt;
    if (at == null) return null;

    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;
    final time = DateFormat.jm().format(at);

    // A clock skewed into the future reads as today rather than as a date.
    if (days <= 0) return l10n.chatHeaderLastSeenToday(time);
    if (days == 1) return l10n.chatHeaderLastSeenYesterday(time);
    return l10n.chatHeaderLastSeenOn(DateFormat('dd/MM/yyyy').format(at), time);
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF000000) : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF000000);
    final subtitle = _subtitle(AppLocalizations.of(context));
    final subtitleColor = isTyping
        ? Theme.of(context).primaryColor
        : (isOnline
              ? const Color(0xFF22C55E)
              : (isDark ? Colors.white38 : const Color(0xFF94A3B8)));

    return AppBar(
      titleSpacing: 0,
      centerTitle: false,
      backgroundColor: bg,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: kToolbarHeight + 4,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE9E7FF),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
      leading: Row(
        children: [
          const SizedBox(width: 4),
          _BackButton(color: fg, onTap: onBack),
        ],
      ),
      title: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _Avatar(
                name: peerName,
                avatarUrl: peerAvatarUrl,
                isOnline: isOnline,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      toTitleCase(peerName),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isTyping)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _TypingIndicator(color: subtitleColor),
                      )
                    else if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [...?actions, const SizedBox(width: 6)],
    );
  }
}

class _BackButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _BackButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.arrow_back_rounded, size: 22, color: color),
        ),
      ),
    );
  }
}

/// Avatar with graceful fallback: shows the peer's photo when it loads,
/// and a colored initials badge if there's no URL or the image fails.
class _Avatar extends StatefulWidget {
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final bool isDark;

  const _Avatar({
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.isDark,
  });

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  bool _imageFailed = false;

  static const List<List<Color>> _gradients = [
    [Color(0xFF0266FA), Color(0xFF3F3DFA)],
    [Color(0xFFEC4899), Color(0xFFF97316)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    [Color(0xFF22C55E), Color(0xFF10B981)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF8B5CF6), Color(0xFFD946EF)],
  ];

  List<Color> get _gradient {
    final name = widget.name.trim();
    if (name.isEmpty) return _gradients.first;
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _gradients[hash % _gradients.length];
  }

  String get _initials {
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  bool get _showImage =>
      !_imageFailed && widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Container(
        //   width: 40,
        //   height: 40,
        //   padding: const EdgeInsets.all(1.5),
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     gradient: LinearGradient(
        //       colors: _gradient,
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //   ),
        //   child:
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isDark ? const Color(0xFF000000) : Colors.white,
          ),
          padding: const EdgeInsets.all(1.5),
          child: ClipOval(
            child: _showImage
                ? CachedNetworkImage(
                    imageUrl: widget.avatarUrl!,
                    cacheManager: MediaCacheService.manager,
                    fit: BoxFit.cover,
                    width: 36,
                    height: 36,
                    placeholder: (context, url) => _initialsBadge(),
                    errorWidget: (context, url, error) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _imageFailed = true);
                      });
                      return _initialsBadge();
                    },
                  )
                : _initialsBadge(),
          ),
        ),
        // ),
        if (widget.isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isDark ? const Color(0xFF000000) : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initialsBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Small animated three-dot "typing…" indicator.
class _TypingIndicator extends StatefulWidget {
  final Color color;

  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).chatHeaderTypingLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final t = (_controller.value - i * 0.2) % 1.0;
                  final scale = 0.5 + 0.5 * sin(t * pi);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Opacity(
                      opacity: 0.4 + 0.6 * scale,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
