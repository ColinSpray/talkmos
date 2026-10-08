part of 'call_signaling_service.dart';

extension CallSignalingRequestCallHistory on CallSignalingService {
  void requestCallHistory({int limit = 50}) {
    _historyLimit = limit;
    _pendingHistoryRequest = true;
    // If the socket isn't up yet, onConnect will re-issue this request once it
    // is, so we never silently drop it.
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('get_call_history', {'limit': limit});
  }
}
