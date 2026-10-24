import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Without this, a notification posted by flutter_local_notifications while
    // the app is foregrounded is dropped by iOS instead of being shown — which
    // is every incoming call that arrives with the app open.
    UNUserNotificationCenter.current().delegate = self

    // APNs registration. FirebaseMessaging swizzles the resulting
    // didRegisterForRemoteNotifications callback to pick up the APNs token,
    // which is what its FCM token is derived from.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Nothing in a video call touches the screen, so without disabling the
    // idle timer iOS dims and locks the device mid-call. See KeepAwakeService.
    let keepAwake = FlutterMethodChannel(
      name: "com.talkmos.apps/keep_awake",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    keepAwake.setMethodCallHandler { call, result in
      guard call.method == "setEnabled" else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.isIdleTimerDisabled = (call.arguments as? Bool) ?? false
      result(nil)
    }
  }
}
