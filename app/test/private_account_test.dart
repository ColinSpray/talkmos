import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/models/user_model.dart';

/// The public/private switch is server state (`User.isPublic` on the backend),
/// surfaced through [UserModel]. These cover the client's half of that contract:
/// parsing it, defaulting it safely, and round-tripping it through the profile
/// cache.
void main() {
  Map<String, dynamic> serverUser({bool? isPublic}) => {
    'success': true,
    'data': {
      '_id': 'u1',
      'name': 'ada',
      if (isPublic != null) 'isPublic': isPublic,
    },
  };

  group('parsing', () {
    test('reads a public account', () {
      expect(UserModel.fromJson(serverUser(isPublic: true)).isPublic, isTrue);
    });

    test('reads a private account', () {
      expect(UserModel.fromJson(serverUser(isPublic: false)).isPublic, isFalse);
    });

    test('a missing field defaults to public', () {
      // The safer direction to be wrong in: showing "Public" understates who
      // can reach you, while defaulting to "Private" would display a
      // restriction the server isn't applying.
      expect(UserModel.fromJson(serverUser()).isPublic, isTrue);
    });
  });

  group('round-trip through the profile cache', () {
    test('private survives being cached and re-read', () {
      // AuthProvider caches the profile as user.toJson() and reads it back with
      // UserModel.fromJson, so a field that doesn't survive that becomes public
      // again on the next cold start.
      final private = UserModel.fromJson(serverUser(isPublic: false));
      final reloaded = UserModel.fromJson(private.toJson());
      expect(reloaded.isPublic, isFalse);
    });

    test('public survives too', () {
      final public = UserModel.fromJson(serverUser(isPublic: true));
      expect(UserModel.fromJson(public.toJson()).isPublic, isTrue);
    });
  });

  group('copyWith', () {
    test('can flip the account private', () {
      final user = UserModel(id: 'u1', name: 'ada');
      expect(user.isPublic, isTrue, reason: 'constructor default is public');
      expect(user.copyWith(isPublic: false).isPublic, isFalse);
    });

    test('leaves the mode alone when not passed', () {
      final private = UserModel(id: 'u1', name: 'ada', isPublic: false);
      expect(private.copyWith(name: 'grace').isPublic, isFalse);
    });
  });
}
