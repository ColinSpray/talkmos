import 'dart:convert';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/http_service.dart';

class ProfileService {
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? username,
    String? avatarUrl,
    String? bio,
    String? location,
    String? status,
  }) async {
    try {
      final response = await HttpService.patch(
        ApiEndpoints.profile,
        body: {
          if (name != null) 'name': name,
          if (username != null) 'username': username,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (bio != null) 'bio': bio,
          if (location != null) 'location': location,
          if (status != null) 'status': status,
        },
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      } else {
        throw body['message'] ?? 'Failed to update profile';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    String? privacyLastSeen,
    bool? privacyReadReceipts,
    bool? notifMessages,
    bool? notifCalls,
    bool? notifCommunities,
    String? theme,
  }) async {
    try {
      final response = await HttpService.patch(
        ApiEndpoints.settings,
        body: {
          if (privacyLastSeen != null) 'privacyLastSeen': privacyLastSeen,
          if (privacyReadReceipts != null)
            'privacyReadReceipts': privacyReadReceipts,
          if (notifMessages != null) 'notifMessages': notifMessages,
          if (notifCalls != null) 'notifCalls': notifCalls,
          if (notifCommunities != null) 'notifCommunities': notifCommunities,
          if (theme != null) 'theme': theme,
        },
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      } else {
        throw body['message'] ?? 'Failed to update settings';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSubscription({
    required String plan,
    String? paymentProvider,
    String? externalTxnId,
  }) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.subscription,
        body: {
          'plan': plan,
          if (paymentProvider != null) 'paymentProvider': paymentProvider,
          if (externalTxnId != null) 'externalTxnId': externalTxnId,
        },
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      } else {
        throw body['message'] ?? 'Failed to upgrade to premium';
      }
    } catch (e) {
      rethrow;
    }
  }
}
