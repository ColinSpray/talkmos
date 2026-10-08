part of 'call_signaling_service.dart';

extension CallSignalingOnCallHistory on CallSignalingService {
  void _onCallHistory(dynamic data) {
    debugPrint('Received call history');
    final history = (data['history'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _callHistory = history;
    _notify();
    onCallHistoryReceived?.call(history);
  }
}
