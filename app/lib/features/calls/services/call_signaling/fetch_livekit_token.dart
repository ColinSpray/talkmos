part of 'call_signaling_service.dart';

extension CallSignalingFetchLivekitToken on CallSignalingService {
  /// Requests a LiveKit access token for [callId] from the backend and waits
  /// (bounded) for the `livekit_token` reply.
  Future<Map<String, dynamic>?> _fetchLivekitToken(String callId) async {
    if (_socket == null || !_socket!.connected) return null;
    _tokenCompleter = Completer<Map<String, dynamic>>();
    _socket!.emit('get_livekit_token', {
      'callId': callId,
      'name': _currentUserName,
    });
    try {
      return await _tokenCompleter!.future.timeout(const Duration(seconds: 8));
    } catch (_) {
      debugPrint('[CallSignaling] Timed out waiting for LiveKit token');
      return null;
    }
  }
}
