import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/titlecase_function.dart';
import '../widgets/settings_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/image_edit_utils.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../../../core/services/media_cache_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _avatarUrlController;

  bool _isUploadingAvatar = false;
  bool _isSaving = false;

  // The (possibly cropped) bytes of a freshly picked avatar, shown as a
  // local preview and uploaded once cropping (if any) is done.
  Uint8List? _pickedImagePreviewBytes;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(
      text: toTitleCase(user?.name ?? ''),
    );
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _avatarUrlController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim(),
      );
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.editProfileScreenUpdateSuccess,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateAvatarSource(ImageSource source) async {
    try {
      final file = await pickImageFrom(source, imageQuality: 85);
      if (file == null) return;

      var bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? 'image/jpeg';

      // Show local preview immediately, before the (optional) crop step.
      setState(() => _pickedImagePreviewBytes = bytes);

      if (!mounted) return;
      final cropped = await cropImageBytes(
        context,
        bytes,
        title: AppLocalizations.of(context).mediaPreviewScreenCropImageTooltip,
        circleCrop: true,
      );
      if (cropped != null) {
        bytes = cropped;
        if (mounted) setState(() => _pickedImagePreviewBytes = bytes);
      }

      if (!mounted) return;
      setState(() => _isUploadingAvatar = true);

      final mediaUrl = await uploadImageBytes(
        bytes,
        mimeType: mimeType,
        fileName: file.name,
      );

      setState(() {
        _avatarUrlController.text = mediaUrl;
        // Keep _pickedImagePreviewBytes for local preview.
      });
    } catch (e) {
      // Revert local preview on failure
      setState(() => _pickedImagePreviewBytes = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).editProfileScreenUploadPhotoFailed(e.toString()),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  void _showAvatarEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final themeColor = Theme.of(context).primaryColor;
        final sheetBg = isDark ? const Color(0xFF1A2436) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF000000);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            36 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.editProfileScreenChangePhotoTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.editProfileScreenChoosePhotoSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _buildSheetOption(
                      icon: Icons.camera_alt_rounded,
                      label: l10n.editProfileScreenCameraLabel,
                      subtitle: l10n.editProfileScreenTakePhotoSubtitle,
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateAvatarSource(ImageSource.camera);
                      },
                      isDark: isDark,
                      themeColor: themeColor,
                      gradient: LinearGradient(
                        colors: [themeColor, themeColor.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSheetOption(
                      icon: Icons.photo_library_rounded,
                      label: l10n.commonGallery,
                      subtitle: l10n.editProfileScreenPickFromLibrarySubtitle,
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateAvatarSource(ImageSource.gallery);
                      },
                      isDark: isDark,
                      themeColor: const Color(0xFF8B5CF6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      ),
                    ),
                  ),
                ],
              ),
              if (_avatarUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImagePreviewBytes = null;
                      _avatarUrlController.text = '';
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  label: Text(
                    l10n.editProfileScreenRemoveCurrentPhoto,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color themeColor,
    required LinearGradient gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final surface = isDark ? AppTheme.darkBg : const Color(0xFFFAF9FF);
    final user = context.watch<AuthProvider>().user;
    final busy = _isSaving || _isUploadingAvatar;

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
          icon: Icon(Icons.arrow_back_rounded, color: primary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          l10n.editProfileScreenTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.commonSave,
                    style: TextStyle(
                      color: busy ? Colors.grey : primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatarBlock(primary, isDark)),
                    const SizedBox(height: 28),

                    SettingsSectionHeader(
                      title: l10n.editProfileScreenBasicInfo,
                      isDark: isDark,
                    ),
                    SettingsCard(
                      isDark: isDark,
                      children: [
                        _buildField(
                          label: l10n.editProfileScreenFullName,
                          hint: l10n.editProfileScreenFullNameHint,
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                          primary: primary,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.editProfileScreenNameEmptyError
                              : null,
                        ),
                        _buildField(
                          label: l10n.commonUsername,
                          hint: l10n.editProfileScreenUsernameHint,
                          controller: _usernameController,
                          icon: Icons.alternate_email_rounded,
                          isDark: isDark,
                          primary: primary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SettingsSectionHeader(
                      title: l10n.commonAbout,
                      isDark: isDark,
                    ),
                    SettingsCard(
                      isDark: isDark,
                      children: [
                        _buildField(
                          label: l10n.editProfileScreenBio,
                          hint: l10n.editProfileScreenBioHint,
                          controller: _bioController,
                          icon: Icons.notes_rounded,
                          isDark: isDark,
                          primary: primary,
                          maxLines: 3,
                        ),
                        _buildField(
                          label: l10n.commonLocation,
                          hint: l10n.editProfileScreenLocationHint,
                          controller: _locationController,
                          icon: Icons.place_outlined,
                          isDark: isDark,
                          primary: primary,
                        ),
                      ],
                    ),

                    if ((user?.email?.isNotEmpty ?? false) ||
                        (user?.phone?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 24),
                      SettingsSectionHeader(
                        title: l10n.commonAccount,
                        isDark: isDark,
                      ),
                      SettingsCard(
                        isDark: isDark,
                        children: [
                          if (user?.email?.isNotEmpty ?? false)
                            _buildReadOnlyRow(
                              icon: Icons.email_outlined,
                              label: l10n.editProfileScreenEmail,
                              value: user!.email!,
                              isDark: isDark,
                            ),
                          if (user?.phone?.isNotEmpty ?? false)
                            _buildReadOnlyRow(
                              icon: Icons.phone_outlined,
                              label: l10n.editProfileScreenPhone,
                              value: user!.phone!,
                              isDark: isDark,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          l10n.editProfileScreenEmailPhoneNotice,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: busy ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primary.withValues(
                            alpha: 0.4,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                l10n.editProfileScreenSaveChanges,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Avatar with a camera badge, plus an upload spinner while one is in
  /// flight so the user can't queue a second pick over the first.
  Widget _buildAvatarBlock(Color primary, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: _isUploadingAvatar ? null : _showAvatarEditOptions,
      child: Column(
        children: [
          Stack(
            children: [
              _buildAvatarWidget(primary),
              if (_isUploadingAvatar)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppTheme.darkBg : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isUploadingAvatar
                ? l10n.editProfileScreenUploading
                : l10n.editProfileScreenChangePhoto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(Color primary) {
    const double radius = 52.0;

    // Local preview takes priority over whatever is stored.
    if (_pickedImagePreviewBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: primary.withValues(alpha: 0.1),
        backgroundImage: MemoryImage(_pickedImagePreviewBytes!),
      );
    }

    if (_avatarUrlController.text.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: primary.withValues(alpha: 0.1),
        backgroundImage: CachedNetworkImageProvider(
          _avatarUrlController.text,
          // URL-keyed so a replaced avatar invalidates the cache.
          cacheKey: _avatarUrlController.text,
          cacheManager: MediaCacheService.manager,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.15),
      child: Text(
        _nameController.text.isNotEmpty
            ? _nameController.text[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }

  /// Editable field styled as a settings-card row: label above, input below,
  /// leading icon matching the other settings screens.
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    required Color primary,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final secondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(icon, size: 22, color: secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  maxLines: maxLines,
                  validator: validator,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: secondary.withValues(alpha: 0.6),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 6, bottom: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primary, width: 1.6),
                    ),
                    errorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.redAccent,
                        width: 1.4,
                      ),
                    ),
                    focusedErrorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.redAccent,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final secondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 16, color: secondary),
        ],
      ),
    );
  }
}
