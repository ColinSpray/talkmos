import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// Rounded, pill-shaped search field styled with Material Design 3-like surface and focus treatment.
class ChatsSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ChatsSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<ChatsSearchBar> createState() => _ChatsSearchBarState();
}

class _ChatsSearchBarState extends State<ChatsSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ChatsSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isFocused = widget.focusNode.hasFocus;

    final primaryColor = colorScheme.primary;
    final onSurfaceColor = colorScheme.onSurface;

    final fillColor = isFocused
        ? (widget.isDark ? colorScheme.surface : Colors.white)
        : (widget.isDark ? const Color(0xFF2A3441) : const Color(0xFFEDEFF2));

    final iconColor = isFocused
        ? primaryColor
        : (widget.isDark ? Colors.white60 : Colors.black45);

    final hintColor = widget.isDark ? Colors.white38 : Colors.black38;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      style: TextStyle(color: onSurfaceColor, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,

        prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 22),

        suffixIcon: widget.showClear
            ? IconButton(
                splashRadius: 20,
                onPressed: widget.onClear,
                icon: Icon(Icons.cancel_rounded, color: hintColor, size: 20),
              )
            : null,

        hintText: AppLocalizations.of(context).commonSearch,
        hintStyle: TextStyle(color: hintColor, fontSize: 16),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: primaryColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
