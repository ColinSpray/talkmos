import 'dart:async';
import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../features/auth/services/auth_service.dart';
import '../core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/analytics_service.dart';
import '../core/services/token_manager.dart';
import '../core/services/http_service.dart';
import '../core/services/device_info_service.dart';
import '../core/config/google_sign_in_config.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  NotificationService? _notificationService;

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  bool _requiresPhoneConfirmation = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get requiresPhoneConfirmation => _requiresPhoneConfirmation;

  AuthProvider() {
    HttpService.onSessionEnded = forceLogout;
    _tryAutoLogin();
  }

  void setNotificationService(NotificationService service) {
    _notificationService = service;
    if (_user != null) _syncFcmToken();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  static const _cachedUserKey = 'cached_user_profile';

  Future<void> _cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Could not cache the user profile: $e');
    }
  }

  Future<UserModel?> _cachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedUserKey);
      if (raw == null || raw.isEmpty) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Could not read the cached user profile: $e');
      return null;
    }
  }

  Future<void> _clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
    } catch (_) {}
  }

  Future<void> _tryAutoLogin() async {
    _setLoading(true);
    try {
      await TokenManager.init();
      final token = TokenManager.token;
      if (token != null) {
        // Come up on the cached profile first, so the app is usable before —
        // and regardless of whether — the network answers.
        _user = await _cachedUser();

        if (_user != null) {
          _isInitialized = true;
          _setLoading(false);
        }

        try {
          final fresh = await _authService.getProfile();
          _user = fresh;
          unawaited(_cacheUser(fresh));
          await _syncFcmToken();
          // Only needed for the fast path above — the plain cache-miss path
          // still gets its one rebuild from finally's _setLoading(false).
          if (_isInitialized) notifyListeners();
        } catch (e) {
          if (_user == null) rethrow;
          debugPrint('Profile refresh failed, continuing offline: $e');
        }
      }
    } catch (_) {
      await logout();
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  Future<void> _syncFcmToken() async {
    final token = TokenManager.token;
    final fcmToken = _notificationService?.fcmToken;
    if (token == null || fcmToken == null) return;
    await _notificationService!.uploadToken(fcmToken);
  }

  Future<bool> register({
    required String name,
    String? email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        device: await DeviceInfoService.buildDevicePayload(
          fcmToken: _notificationService?.fcmToken,
        ),
      );
      await _saveUser(user);
      _setLoading(false);
      AnalyticsService.logEvent('sign_up', parameters: {'method': 'email'});
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signin({
    String? email,
    String? username,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await _authService.signin(
        email: email,
        username: username,
        password: password,
        device: await DeviceInfoService.buildDevicePayload(
          fcmToken: _notificationService?.fcmToken,
        ),
      );
      await _saveUser(user);
      _setLoading(false);
      AnalyticsService.logEvent('login', parameters: {'method': 'password'});
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ─── Phone / OTP auth ─────────────────────────────────────────────────────

  /// Sends an OTP to [phone]. Returns the dev code (while there's no SMS
  /// provider) for auto-fill, or null. Throws on failure.
  Future<String?> sendPhoneOtp(String phone) async {
    _setError(null);
    return _authService.sendPhoneOtp(phone);
  }

  Future<bool> verifyPhoneOtp(String phone, String code) async {
    _setError(null);
    final result = await _authService.verifyPhoneOtp(
      phone,
      code,
      device: await DeviceInfoService.buildDevicePayload(
        fcmToken: _notificationService?.fcmToken,
      ),
    );
    await _saveUser(result.user);
    AnalyticsService.logEvent(
      result.isNewUser ? 'sign_up' : 'login',
      parameters: {'method': 'phone'},
    );
    return result.isNewUser;
  }

  /// Completes a new phone user's profile (name + username) and finalizes the
  /// session, which flips [isAuthenticated] and routes into the app.
  Future<void> completePhoneProfile({
    required String name,
    required String username,
  }) async {
    final user = await _authService.updateProfile(
      name: name,
      username: username,
    );
    await _saveUser(user);
  }

  Future<void>? _googleSignInInit;

  Future<void> _ensureGoogleSignInInitialized() =>
      _googleSignInInit ??= GoogleSignIn.instance.initialize(
        clientId: GoogleSignInConfig.clientId,
        serverClientId: GoogleSignInConfig.serverClientId,
      );

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      // 1. Trigger Google Sign-In flow
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      // 2. Obtain details from request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      String? idToken;

      // 3. Try obtaining Firebase ID Token if Firebase Auth is active
      try {
        // Authentication now yields an ID token only — access tokens come from
        // the authorization client, and Firebase doesn't need one here.
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);
        idToken = await userCredential.user?.getIdToken();
      } catch (fbErr) {
        debugPrint('[AuthProvider] Firebase Auth sign-in note: $fbErr');
        idToken = googleAuth.idToken;
      }

      final device = await DeviceInfoService.buildDevicePayload(
        fcmToken: _notificationService?.fcmToken,
      );

      // 5. Sign in to backend with token and user profile fallback
      final result = await _authService.signInWithGoogle(
        idToken: idToken ?? googleAuth.idToken,
        email: googleUser.email,
        name: googleUser.displayName,
        picture: googleUser.photoUrl,
        device: device,
      );
      final hasPhone =
          result.user.phone != null && result.user.phone!.trim().isNotEmpty;
      _requiresPhoneConfirmation = result.isNewUser && !hasPhone;
      await _saveUser(result.user);
      _setLoading(false);
      AnalyticsService.logEvent(
        result.isNewUser ? 'sign_up' : 'login',
        parameters: {'method': 'google'},
      );
      return true;
    } on GoogleSignInException catch (e) {
      // Backing out of the account picker throws now rather than returning
      // null, and it isn't a failure worth putting on screen.
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _setError(e.description ?? e.code.name);
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void dismissPhoneConfirmation() {
    _requiresPhoneConfirmation = false;
    notifyListeners();
  }

  Future<void> updatePrivacySettings({
    bool? readReceiptsEnabled,
    String? lastSeenVisibility,
    String? profilePhotoVisibility,
    bool? isPublic,
  }) async {
    final updatedUser = await _authService.updateProfile(
      readReceiptsEnabled: readReceiptsEnabled,
      lastSeenVisibility: lastSeenVisibility,
      profilePhotoVisibility: profilePhotoVisibility,
      isPublic: isPublic,
    );
    await _saveUser(updatedUser);
  }

  Future<void> updatePhone(String phone) async {
    _setLoading(true);
    try {
      final updatedUser = await _authService.updateProfile(phone: phone);
      final finalUser =
          (updatedUser.phone != null && updatedUser.phone!.isNotEmpty)
          ? updatedUser
          : (_user != null ? _user!.copyWith(phone: phone) : updatedUser);
      await _saveUser(finalUser);
      _requiresPhoneConfirmation = false;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> _saveUser(UserModel user) async {
    _user = user;
    notifyListeners();
    unawaited(_cacheUser(user));
    try {
      await _syncFcmToken();
      // Tag all Crashlytics reports with the logged-in user's ID.
      await FirebaseCrashlytics.instance.setUserIdentifier(user.id);
      await AnalyticsService.setUserId(user.id);
    } catch (e) {
      debugPrint('Error syncing FCM token or Crashlytics user ID: $e');
    }
  }

  Future<void> logout() async {
    AnalyticsService.logEvent('logout');
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Backend logout call failed, continuing locally: $e');
    }
    await _localLogout();
  }

  Future<void> forceLogout() async {
    await _localLogout();
  }

  Future<void> _localLogout() async {
    _user = null;
    _setError(null);
    await TokenManager.clear();
    // The cached profile outlives the token otherwise, and the next sign-in on
    // this device would come up as the previous account until its fetch lands.
    await _clearCachedUser();
    // Clear the Crashlytics user identifier on logout.
    await FirebaseCrashlytics.instance.setUserIdentifier('');
    await AnalyticsService.setUserId(null);
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (TokenManager.token == null) return;
    _setLoading(true);
    try {
      final updatedUser = await _authService.getProfile();
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile in AuthProvider: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? username,
    String? avatarUrl,
    String? bio,
    String? location,
    String? status,
  }) async {
    if (TokenManager.token == null) return;
    _setLoading(true);
    try {
      final updatedUser = await _authService.updateProfile(
        name: name,
        username: username,
        avatarUrl: avatarUrl,
        bio: bio,
        location: location,
        status: status,
      );
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
