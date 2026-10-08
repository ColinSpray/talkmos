part of 'call_signaling_service.dart';

extension CallSignalingReconcileFromNativeCall on CallSignalingService {
  Future<void> reconcileFromNativeCall(String currentUserId) async {
    await CallNotificationService.consumeLaunchDetails();
  }
}
