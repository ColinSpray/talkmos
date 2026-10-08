part of 'nearby_service.dart';

extension NearbyServiceSendRequest on NearbyService {
  Future<void> sendNearbyRequest({
    required String userId,
    required String message,
  }) async {
    final response = await HttpService.post(
      ApiEndpoints.nearbyRequest,
      body: {'userId': userId, 'message': message},
    );
    _parse(response);
  }
}
