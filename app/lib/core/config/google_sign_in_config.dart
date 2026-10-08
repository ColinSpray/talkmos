import 'package:flutter/foundation.dart';

/// OAuth client ids from `android/app/google-services.json` and
/// `ios/Runner/GoogleService-Info.plist`.
class GoogleSignInConfig {
  /// Web client (`client_type: 3`). Required on Android, and the audience
  /// Firebase Auth expects on the returned ID token.
  static const String serverClientId =
      '282430200722-rs8qae32jq09kl27b0f4hf9fvsnaov4m.apps.googleusercontent.com';

  static const String _iosClientId =
      '282430200722-0oqsm3d0dvfsvf381hdbv9c3mr41587p.apps.googleusercontent.com';

  /// Android reads its own client from google-services.json.
  static String? get clientId => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => _iosClientId,
    _ => null,
  };
}
