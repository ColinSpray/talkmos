import 'dart:convert';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/http_service.dart';
import '../../../models/device_model.dart';

class DeviceService {
  Future<List<DeviceModel>> getDevices() async {
    final response = await HttpService.get(ApiEndpoints.devices);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> list = data['data'];
      return list
          .map((e) => DeviceModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw data['message'] ?? 'Failed to fetch devices';
  }

  /// Logs out [deviceId] — any of the caller's own devices, including the
  /// current one (equivalent to a regular logout for that case).
  Future<void> revokeDevice(String deviceId) async {
    final response = await HttpService.delete(ApiEndpoints.device(deviceId));
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw data['message'] ?? 'Failed to log out device';
    }
  }
}
