import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

/// Exception thrown when an API request fails.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class RateLimitException extends ApiException {
  /// How long the server asked us to wait, from its `Retry-After` header.
  final Duration retryAfter;

  RateLimitException(super.message, {required this.retryAfter})
    : super(statusCode: 429);
}

class HttpService {
  static final http.Client _client = http.Client();

  static void Function()? onSessionEnded;

  /// The endpoints that answer 401 for wrong credentials rather than for a
  /// dead session — nobody is signed in on these yet.
  static const Set<String> _credentialPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/google',
    '/auth/phone/send-otp',
    '/auth/phone/verify-otp',
    '/auth/forgot-password',
    '/auth/reset-password',
  };

  /// Whether a response says the session is over. Any 401 off a credential
  /// endpoint means the token we sent is no longer accepted — expired, or
  /// signed before the server's secret changed. A revoked session
  /// (`SESSION_REVOKED`) is only one of the ways that happens, and treating it
  /// as the only one leaves the app running against a token nothing accepts.
  static bool endsSession(int statusCode, String path) =>
      statusCode == 401 && !_credentialPaths.any(path.endsWith);

  static void _checkSessionEnded(http.Response response) {
    final path = response.request?.url.path ?? '';
    if (!endsSession(response.statusCode, path)) return;
    debugPrint('[HttpService] session rejected (401) on $path');
    onSessionEnded?.call();
  }

  /// Generate the default headers for the API requests.
  static Map<String, String> _headers() {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final token = TokenManager.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static const int _maxRateLimitRetries = 1;

  static Duration _retryAfterOf(http.Response response) {
    final raw = response.headers['retry-after'];
    final seconds = int.tryParse(raw ?? '') ?? 2;
    return Duration(seconds: seconds.clamp(1, 30));
  }

  /// Centralized wrapper to execute HTTP requests inside a global try-catch block.
  static Future<http.Response> _execute(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request();

      for (
        var attempt = 0;
        response.statusCode == 429 && attempt < _maxRateLimitRetries;
        attempt++
      ) {
        final wait = _retryAfterOf(response);
        debugPrint(
          '[HttpService] rate limited — retrying in ${wait.inSeconds}s',
        );
        await Future.delayed(wait);
        response = await request();
      }

      if (response.statusCode == 429) {
        throw RateLimitException(
          'Too many requests. Please slow down and try again shortly.',
          retryAfter: _retryAfterOf(response),
        );
      }

      _checkSessionEnded(response);
      return response;
    } on SocketException catch (e) {
      debugPrint('[HttpService] Network connection error: $e');
      throw ApiException('No internet connection. Please check your network.');
    } on HttpException catch (e) {
      debugPrint('[HttpService] HTTP protocol error: $e');
      throw ApiException('Communication error with server.');
    } on FormatException catch (e) {
      debugPrint('[HttpService] Data format error: $e');
      throw ApiException('Invalid response format from server.');
    } catch (e) {
      debugPrint('[HttpService] Unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  /// Perform a GET request.
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return _execute(() async {
      final finalHeaders = {..._headers(), ...?headers};
      return await _client.get(url, headers: finalHeaders);
    });
  }

  /// Perform a POST request.
  static Future<http.Response> post(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _execute(() async {
      final finalHeaders = {..._headers(), ...?headers};
      final encodedBody = body is Map || body is List ? jsonEncode(body) : body;
      return await _client.post(url, headers: finalHeaders, body: encodedBody);
    });
  }

  /// Perform a PUT request.
  static Future<http.Response> put(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _execute(() async {
      final finalHeaders = {..._headers(), ...?headers};
      final encodedBody = body is Map || body is List ? jsonEncode(body) : body;
      return await _client.put(url, headers: finalHeaders, body: encodedBody);
    });
  }

  /// Perform a PATCH request.
  static Future<http.Response> patch(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _execute(() async {
      final finalHeaders = {..._headers(), ...?headers};
      final encodedBody = body is Map || body is List ? jsonEncode(body) : body;
      return await _client.patch(url, headers: finalHeaders, body: encodedBody);
    });
  }

  /// Perform a DELETE request.
  static Future<http.Response> delete(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _execute(() async {
      final finalHeaders = {..._headers(), ...?headers};
      final encodedBody = body != null
          ? (body is Map || body is List ? jsonEncode(body) : body)
          : null;
      return await _client.delete(
        url,
        headers: finalHeaders,
        body: encodedBody,
      );
    });
  }
}
