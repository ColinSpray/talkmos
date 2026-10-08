import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/http_service.dart';
import '../features/nearby/services/nearby_location.dart';
import '../features/nearby/services/nearby_prefs.dart';
import '../features/nearby/services/nearby_service/nearby_service.dart';
import '../models/nearby_user_model.dart';

enum NearbyStatus {
  /// Nothing running — the screen is closed or was never opened.
  idle,

  /// Permission checks and the first heartbeat are in flight.
  starting,

  /// Polling for people around.
  running,

  /// The account has not opted in yet; the consent sheet decides.
  needsConsent,

  /// The system location toggle is off, so no fix is obtainable at all.
  locationOff,

  /// The user declined the location permission.
  locationDenied,

  /// Something else went wrong; [NearbyProvider.errorMessage] says what.
  error,
}

enum NearbyFilter { all, rightHere }

class NearbyProvider extends ChangeNotifier {
  NearbyProvider({NearbyService? service})
    : _service = service ?? NearbyService();

  final NearbyService _service;

  static const Duration _heartbeatInterval = Duration(seconds: 30);

  static const Duration _positionMaxAge = Duration(minutes: 2);

  Timer? _timer;
  bool _tickInFlight = false;

  int _generation = 0;

  Position? _position;
  DateTime? _positionAt;

  NearbyStatus _status = NearbyStatus.idle;
  String? _errorMessage;
  List<NearbyUserModel> _users = const [];
  final Set<String> _requestedIds = {};

  NearbyStatus get status => _status;
  String? get errorMessage => _errorMessage;

  NearbyFilter _filter = NearbyFilter.all;
  NearbyFilter get filter => _filter;

  void setFilter(NearbyFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  /// The slice the current filter asks for.
  List<NearbyUserModel> get users => switch (_filter) {
    NearbyFilter.all => _users,
    NearbyFilter.rightHere =>
      _users.where((u) => u.tier == NearbyTier.rightHere).toList(),
  };

  /// Unfiltered, for the counts on the filter chips — they have to show what
  /// is behind a tab the user isn't looking at.
  List<NearbyUserModel> get allUsers => _users;
  int get rightHereCount =>
      _users.where((u) => u.tier == NearbyTier.rightHere).length;

  bool get hasPosition => _position != null;

  bool hasRequested(String userId) => _requestedIds.contains(userId);

  bool _canPromptForLocation = true;
  bool get canPromptForLocation => _canPromptForLocation;

  void _set(NearbyStatus status, {String? error}) {
    _status = status;
    _errorMessage = error;
    debugPrint(
      '[Nearby] status -> ${status.name}${error == null ? '' : ': $error'}',
    );
    notifyListeners();
  }

  Future<void> enableAndStart() async {
    try {
      await _service.setNearbyEnabled(true);
    } catch (e) {
      _set(NearbyStatus.error, error: e.toString());
      return;
    }
    await NearbyPrefs.setEnabled(true);
    await NearbyLocation.requestPermission();
    await start();
  }

  static Future<void> reportPosition() async {
    if (!await NearbyPrefs.isEnabled()) return;

    final position = await NearbyLocation.current();
    if (position == null) return;
    await NearbyService().ping(position.latitude, position.longitude);
  }

  Future<String?> disable() async {
    try {
      await _service.setNearbyEnabled(false);
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
    await stop();
    await NearbyPrefs.setEnabled(false);
    return null;
  }

  Future<void> start() async {
    if (_status == NearbyStatus.starting || _status == NearbyStatus.running) {
      return;
    }
    final generation = ++_generation;
    _set(NearbyStatus.starting);

    if (!await NearbyLocation.serviceEnabled()) {
      return _setIfCurrent(generation, NearbyStatus.locationOff);
    }
    if (!await NearbyLocation.hasPermission()) {
      // Read before the state is set, because it decides what the screen can
      // offer: a dialog the OS will still show, or a trip to Settings.
      _canPromptForLocation = await NearbyLocation.canPrompt();
      return _setIfCurrent(generation, NearbyStatus.locationDenied);
    }

    try {
      await _refresh();
    } on ApiException catch (e) {
      // Not an error — it's the first-run path, and the consent sheet is what
      // resolves it.
      if (e.statusCode == 403) {
        await NearbyPrefs.setEnabled(false);
        return _setIfCurrent(generation, NearbyStatus.needsConsent);
      }
      return _setIfCurrent(generation, NearbyStatus.error, error: e.message);
    } catch (e) {
      return _setIfCurrent(generation, NearbyStatus.error, error: e.toString());
    }

    // Drift the other way: opted in from another device, so this one has not
    // recorded it yet.
    await NearbyPrefs.setEnabled(true);
    if (generation != _generation) return;
    _set(NearbyStatus.running);
    _timer = Timer.periodic(_heartbeatInterval, (_) => _tick());
  }

  void _setIfCurrent(int generation, NearbyStatus status, {String? error}) {
    if (generation != _generation) return;
    _set(status, error: error);
  }

  Future<void> stop() async {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _users = const [];
    _requestedIds.clear();
    _position = null;
    _positionAt = null;
    if (_status != NearbyStatus.idle) _set(NearbyStatus.idle);
  }

  Future<Position?> _freshPosition() async {
    final at = _positionAt;
    if (_position != null &&
        at != null &&
        DateTime.now().difference(at) < _positionMaxAge) {
      return _position;
    }
    final position = await NearbyLocation.current();
    if (position != null) {
      _position = position;
      _positionAt = DateTime.now();
    }
    return _position;
  }

  /// One round trip. Throws, so start() can tell a 403 from a real failure;
  /// [_tick] is the one that swallows.
  Future<void> _refresh() async {
    final position = await _freshPosition();
    final found = await _service.heartbeat(
      lat: position?.latitude,
      lng: position?.longitude,
    );
    _users = found.where((u) => !_requestedIds.contains(u.id)).toList();
    debugPrint('[Nearby] heartbeat -> ${found.length} user(s)');
    notifyListeners();
  }

  Future<void> _tick() async {
    // A slow response must not let ticks stack up — that would turn one
    // degraded request into a queue of them.
    if (_tickInFlight || _status != NearbyStatus.running) return;
    _tickInFlight = true;
    try {
      await _refresh();
    } on RateLimitException catch (e) {
      // Transient by definition; the next tick is past the window.
      debugPrint('[Nearby] heartbeat rate limited: ${e.message}');
    } catch (e) {
      debugPrint('[Nearby] heartbeat failed: $e');
    } finally {
      _tickInFlight = false;
    }
  }

  Future<String?> sendRequest({
    required String userId,
    required String message,
  }) async {
    try {
      await _service.sendNearbyRequest(userId: userId, message: message);
      _requestedIds.add(userId);
      _users = _users.where((u) => u.id != userId).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> requestPermissionAndStart() async {
    await NearbyLocation.requestPermission();
    await start();
  }

  /// Sends the user to system settings to grant location, for the two states
  /// where nothing else can move them forward.
  Future<void> openSettings() => NearbyLocation.openSettings();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
