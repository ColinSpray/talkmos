part of 'socket_service.dart';

extension SocketServiceHandleSocketDisconnected on SocketService {
  void _handleSocketDisconnected() {
    debugPrint('Disconnected from Socket Server');
    _isConnected = false;
    _notify();
  }
}
