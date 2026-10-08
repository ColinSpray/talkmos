import 'package:flutter/material.dart';

class TalkmosListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry contentPadding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const TalkmosListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: contentPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );

    final finalBorderRadius = borderRadius ?? BorderRadius.circular(16);

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: finalBorderRadius,
        child: content,
      );
    }

    return Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: finalBorderRadius,
      clipBehavior: backgroundColor != null ? Clip.antiAlias : Clip.none,
      child: content,
    );
  }
}
