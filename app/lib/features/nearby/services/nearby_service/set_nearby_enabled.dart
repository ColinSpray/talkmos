part of 'nearby_service.dart';

extension NearbyServiceSetEnabled on NearbyService {
  Future<bool> setNearbyEnabled(bool enabled) async {
    final response = await HttpService.patch(
      ApiEndpoints.nearbySettings,
      body: {'enabled': enabled},
    );
    final body = _parse(response);
    return (body['data']?['nearbyEnabled'] ?? false) == true;
  }
}
