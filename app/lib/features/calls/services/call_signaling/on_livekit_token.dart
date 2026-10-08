part of 'call_signaling_service.dart';

extension CallSignalingOnLivekitToken on CallSignalingService {
  void _onLivekitToken(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (_tokenCompleter != null && !_tokenCompleter!.isCompleted) {
      _tokenCompleter!.complete(map);
    }
  }
}
