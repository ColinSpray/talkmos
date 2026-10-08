import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../../../providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/titlecase_function.dart';
import '../../../models/user_model.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class BlockedContactsScreen extends StatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  State<BlockedContactsScreen> createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends State<BlockedContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlockProvider>().loadBlockedUsers();
    });
  }

  Future<void> _unblock(UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final name = toTitleCase(user.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.blockedContactsScreenUnblockConfirmTitle(name)),
        content: Text(l10n.blockedContactsScreenUnblockConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonUnblock),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<BlockProvider>().unblockUser(user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.blockedContactsScreenUnblockFailed(e.toString()),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkBg : const Color(0xFFFAF9FF);
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    final blockState = context.watch<BlockProvider>();

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFE3E3EF),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.blockedContactsScreenTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: blockState.isLoading && blockState.blockedUsers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : blockState.blockedUsers.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 48,
                        color: subtextColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.blockedContactsScreenEmptyTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.blockedContactsScreenEmptyDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: subtextColor),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: blockState.blockedUsers.length,
                itemBuilder: (_, i) {
                  final user = blockState.blockedUsers[i];
                  return ListTile(
                    leading: AvatarCircle(
                      imageUrl: user.avatarUrl,
                      radius: 22,
                      backgroundColor: theme.primaryColor.withValues(
                        alpha: 0.12,
                      ),
                      fallback: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    title: Text(
                      toTitleCase(user.name),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: user.username != null && user.username!.isNotEmpty
                        ? Text(
                            '@${user.username}',
                            style: TextStyle(color: subtextColor),
                          )
                        : null,
                    trailing: TextButton(
                      onPressed: () => _unblock(user),
                      child: Text(l10n.commonUnblock),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
