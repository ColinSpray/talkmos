import 'dart:convert';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/http_service.dart';
import '../../../models/user_model.dart';
import '../../../core/services/token_manager.dart';

class AuthService {
  Future<UserModel> register({
    required String name,
    String? email,
    required String password,
    Map<String, dynamic>? device,
  }) async {
    final response = await HttpService.post(
      ApiEndpoints.register,
      body: {
        'name': name,
        if (email != null) 'email': email,
        'password': password,
        if (device != null) 'device': device,
      },
    );
    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      final token = data['data']?['token'] ?? data['token'];
      if (token != null) {
        await TokenManager.setToken(token);
      }
      return UserModel.fromJson(data);
    }
    throw data['message'] ?? 'Failed to register';
  }

  Future<UserModel> signin({
    String? email,
    String? username,
    required String password,
    Map<String, dynamic>? device,
  }) async {
    final response = await HttpService.post(
      ApiEndpoints.login,
      body: {
        if (email != null) 'email': email,
        if (username != null) 'username': username,
        'password': password,
        if (device != null) 'device': device,
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']?['token'] ?? data['token'];
      if (token != null) {
        await TokenManager.setToken(token);
      }
      return UserModel.fromJson(data);
    }
    throw data['message'] ?? 'Failed to sign in';
  }

  Future<UserModel> getProfile() async {
    final response = await HttpService.get(ApiEndpoints.authProfile);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data);
    }
    throw data['message'] ?? 'Failed to fetch profile';
  }

  Future<void> forgotPassword(String identifier) async {
    final isEmail = identifier.contains('@');
    final response = await HttpService.post(
      ApiEndpoints.forgotPassword,
      body: {if (isEmail) 'email': identifier else 'phone': identifier},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw data['message'] ?? 'Failed to send reset code';
    }
  }

  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String password,
  }) async {
    final isEmail = identifier.contains('@');
    final response = await HttpService.post(
      ApiEndpoints.resetPassword,
      body: {
        if (isEmail) 'email': identifier else 'phone': identifier,
        'code': code,
        'password': password,
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw data['message'] ?? 'Failed to reset password';
    }
  }

  Future<void> logout() async {
    await HttpService.post(ApiEndpoints.logout);
  }

  Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final response = await HttpService.put(
        ApiEndpoints.fcmToken,
        body: {'fcmToken': fcmToken},
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<GoogleAuthResult> signInWithGoogle({
    String? idToken,
    String? email,
    String? name,
    String? picture,
    Map<String, dynamic>? device,
  }) async {
    final response = await HttpService.post(
      ApiEndpoints.googleLogin,
      body: {
        if (idToken != null) 'idToken': idToken,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (picture != null) 'picture': picture,
        if (device != null) 'device': device,
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']?['token'] ?? data['token'];
      if (token != null) {
        await TokenManager.setToken(token);
      }
      final user = UserModel.fromJson(data);
      final isNewUser =
          data['isNewUser'] == true ||
          user.phone == null ||
          user.phone!.isEmpty;
      return GoogleAuthResult(user: user, isNewUser: isNewUser);
    }
    throw data['message'] ?? 'Failed to sign in with Google';
  }

  /// Requests an OTP for [phone]. Returns the dev code (backend echoes it while
  /// there's no SMS provider) so the client can auto-fill it, or null.
  Future<String?> sendPhoneOtp(String phone) async {
    final response = await HttpService.post(
      ApiEndpoints.sendPhoneOtp,
      body: {'phone': phone},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['devCode']?.toString();
    }
    throw data['message'] ?? 'Failed to send verification code';
  }

  /// Verifies [code] for [phone]. On success saves the token and returns the
  /// user plus whether they still need to complete their profile.
  Future<({bool isNewUser, UserModel user})> verifyPhoneOtp(
    String phone,
    String code, {
    Map<String, dynamic>? device,
  }) async {
    final response = await HttpService.post(
      ApiEndpoints.verifyPhoneOtp,
      body: {
        'phone': phone,
        'code': code,
        if (device != null) 'device': device,
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['data']?['token'] ?? data['token'];
      if (token != null) {
        await TokenManager.setToken(token);
      }
      return (
        isNewUser: data['isNewUser'] == true,
        user: UserModel.fromJson(data),
      );
    }
    throw data['message'] ?? 'Invalid or expired code';
  }

  Future<UserModel> updateProfile({
    String? name,
    String? username,
    String? avatarUrl,
    String? bio,
    String? location,
    String? status,
    String? phone,
    bool? notificationsEnabled,
    bool? notificationPreviewEnabled,
    bool? readReceiptsEnabled,
    String? lastSeenVisibility,
    String? profilePhotoVisibility,
    bool? isPublic,
  }) async {
    final response = await HttpService.patch(
      ApiEndpoints.authProfile,
      body: {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (status != null) 'status': status,
        if (phone != null) 'phone': phone,
        if (notificationsEnabled != null)
          'notificationsEnabled': notificationsEnabled,
        if (notificationPreviewEnabled != null)
          'notificationPreviewEnabled': notificationPreviewEnabled,
        if (readReceiptsEnabled != null)
          'readReceiptsEnabled': readReceiptsEnabled,
        if (lastSeenVisibility != null)
          'lastSeenVisibility': lastSeenVisibility,
        if (profilePhotoVisibility != null)
          'profilePhotoVisibility': profilePhotoVisibility,
        if (isPublic != null) 'isPublic': isPublic,
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data);
    }
    throw data['message'] ?? 'Failed to update profile';
  }
}

class GoogleAuthResult {
  final UserModel user;
  final bool isNewUser;

  GoogleAuthResult({required this.user, required this.isNewUser});
}
