import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/token_manager.dart';
import 'nearby_location.dart';
import 'nearby_prefs.dart';
import 'nearby_service/nearby_service.dart';

class NearbyLocateResponder {
  NearbyLocateResponder._();

  /// The FCM `type` this responds to. Data-only, so nothing is rendered.
  static const String messageType = 'nearby_locate';

  static const Duration _fixTimeout = Duration(seconds: 6);

  static Future<void> handle() async {
    if (TokenManager.token == null) await TokenManager.init();
    if (TokenManager.token == null) {
      debugPrint('[Nearby] locate push ignored: not signed in');
      return;
    }

    if (!await NearbyPrefs.isEnabled()) {
      debugPrint('[Nearby] locate push ignored: Nearby is off');
      return;
    }

    final position = await _resolve();
    if (position == null) {
      // The server seeds from its own last-known copy when nothing arrives,
      // so going quiet here is a supported outcome rather than a dead end.
      debugPrint('[Nearby] locate push: no position available');
      return;
    }

    await NearbyService().ping(position.latitude, position.longitude);
    debugPrint('[Nearby] locate push answered');
  }

  /// A live fix if one lands inside the budget, otherwise whatever the OS
  /// already had. Returns null only when the device can offer neither.
  static Future<Position?> _resolve() async {
    if (!await NearbyLocation.serviceEnabled()) return null;
    if (!await NearbyLocation.hasPermission()) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: _fixTimeout,
        ),
      );
    } catch (e) {
      debugPrint('[Nearby] locate push: live fix failed ($e), falling back');
      return NearbyLocation.lastKnown();
    }
  }
}
