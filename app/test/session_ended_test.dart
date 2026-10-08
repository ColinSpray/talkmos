import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/core/services/http_service.dart';
import 'package:talkmos/core/services/socket_auth_error.dart';

void main() {
  group('a 401 ends the session', () {
    test('on any authenticated endpoint', () {
      expect(HttpService.endsSession(401, '/api/chats/recent'), isTrue);
      expect(HttpService.endsSession(401, '/api/auth/'), isTrue);
    });

    test('but not when signing in — that is a wrong password', () {
      expect(HttpService.endsSession(401, '/api/auth/login'), isFalse);
      expect(
        HttpService.endsSession(401, '/api/auth/phone/verify-otp'),
        isFalse,
      );
      expect(HttpService.endsSession(401, '/api/auth/register'), isFalse);
    });

    test('and no other status does', () {
      expect(HttpService.endsSession(403, '/api/chats/recent'), isFalse);
      expect(HttpService.endsSession(200, '/api/chats/recent'), isFalse);
    });
  });

  group('socket handshake failures', () {
    test('a rejected token is not worth retrying', () {
      expect(isSocketAuthFailure('Authentication failed'), isTrue);
      expect(isSocketAuthFailure('Authentication required'), isTrue);
      expect(isSocketAuthFailure('Session revoked'), isTrue);
    });

    test('a network failure is', () {
      expect(isSocketAuthFailure('websocket error'), isFalse);
      expect(isSocketAuthFailure('timeout'), isFalse);
      expect(isSocketAuthFailure(null), isFalse);
    });
  });
}
