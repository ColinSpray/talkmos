import 'dart:convert';
import '../config/api_endpoints.dart';
import '../services/http_service.dart';
import 'app_language.dart';

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  Future<String> translate({
    required String text,
    required AppLanguage target,
  }) async {
    final response = await HttpService.post(
      ApiEndpoints.translate,
      body: {'text': text, 'source': 'auto', 'target': target.code},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      return body['data']['translatedText']?.toString() ?? '';
    }
    throw ApiException(
      body['message']?.toString() ?? 'Translation failed',
      statusCode: response.statusCode,
    );
  }
}
