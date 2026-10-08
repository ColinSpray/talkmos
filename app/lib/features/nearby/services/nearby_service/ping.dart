part of 'nearby_service.dart';

extension NearbyServicePing on NearbyService {
  Future<void> ping(double lat, double lng) async {
    try {
      await HttpService.post(
        ApiEndpoints.nearbyPing,
        body: {'lat': lat, 'lng': lng},
      );
    } catch (e) {
      debugPrint('[Nearby] ping failed: $e');
    }
  }
}
