import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get backendUrl {
    final url = dotenv.env['BACKEND_URL'];
    if (url != null && url.isNotEmpty) {
      return url;
    }
    throw Exception('BACKEND_URL not configured in .env file');
  }

  static String get baseApiUrl => '$backendUrl/api/v1';

  static String get authUrl => '$baseApiUrl/auth';
  static String get callsUrl => '$baseApiUrl/calls';
  static String get chatUrl => '$baseApiUrl/chat';
  static String get profileUrl => '$baseApiUrl/profile';
  static String get storyUrl => '$baseApiUrl/stories';
  static String get friendUrl => '$baseApiUrl/friends';
  static String get userSearchUrl => '$baseApiUrl/users';
  static String get translateUrl => '$baseApiUrl/translate';
  static String get keysUrl => '$baseApiUrl/keys';

  static String get socketUrl => backendUrl;
}
