import 'package:flutter/foundation.dart';

/// OAuth client ids from `android/app/google-services.json` and
/// `ios/Runner/GoogleService-Info.plist`.
class GoogleSignInConfig {
  /// Web client (`client_type: 3`). Required on Android, and the audience
  /// Firebase Auth expects on the returned ID token.
  static const String serverClientId =
      '383040801916-ojkem35tcjb9d47568lh875o7f5h0sho.apps.googleusercontent.com';

  static const String _iosClientId =
      '383040801916-doqs6un4g349gumia6kh1jkm90ntv8ap.apps.googleusercontent.com';

  /// Android reads its own client from google-services.json.
  static String? get clientId => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => _iosClientId,
    _ => null,
  };
}
