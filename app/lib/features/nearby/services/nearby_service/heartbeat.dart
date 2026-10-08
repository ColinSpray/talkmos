part of 'nearby_service.dart';

extension NearbyServiceHeartbeat on NearbyService {
  Future<List<NearbyUserModel>> heartbeat({double? lat, double? lng}) async {
    final response = await HttpService.post(
      ApiEndpoints.nearbyHeartbeat,
      body: {
        if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
      },
    );
    final body = _parse(response);
    final data = body['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(NearbyUserModel.fromJson)
        .toList();
  }
}
