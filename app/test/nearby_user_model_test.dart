import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/models/nearby_user_model.dart';

void main() {
  group('NearbyUserModel.fromJson', () {
    test('decodes a full payload', () {
      final user = NearbyUserModel.fromJson({
        '_id': 'u1',
        'name': 'asha',
        'username': 'asha_r',
        'avatarUrl': 'https://cdn.example/a.jpg',
        'isVerified': true,
        'tier': 'right_here',
      });

      expect(user.id, 'u1');
      expect(user.name, 'asha');
      expect(user.username, 'asha_r');
      expect(user.isVerified, isTrue);
      expect(user.tier, NearbyTier.rightHere);
    });

    test('a withheld avatar arrives as empty, not null', () {
      // The server blanks avatarUrl when profilePhotoVisibility isn't
      // 'Everyone', so the card has to render a placeholder rather than crash.
      final user = NearbyUserModel.fromJson({
        '_id': 'u2',
        'name': 'ravi',
        'avatarUrl': '',
        'tier': 'right_here',
      });

      expect(user.avatarUrl, isEmpty);
      expect(user.username, isEmpty);
      expect(user.isVerified, isFalse);
    });

    test('an unknown tier falls back to the vaguest one', () {
      // A newer server sending a tier this build has never heard of must not
      // throw, and must not be read as closer than it is.
      final user = NearbyUserModel.fromJson({
        '_id': 'u3',
        'name': 'sam',
        'tier': 'same_table',
      });

      expect(user.tier, NearbyTier.nearby);
    });

    test('a missing tier falls back the same way', () {
      final user = NearbyUserModel.fromJson({'_id': 'u4', 'name': 'kiran'});
      expect(user.tier, NearbyTier.nearby);
    });

    test('survives a payload missing everything', () {
      final user = NearbyUserModel.fromJson({});
      expect(user.id, isEmpty);
      expect(user.name, isEmpty);
      expect(user.tier, NearbyTier.nearby);
    });
  });
}
