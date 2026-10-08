import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talkmos/core/services/app_permissions.dart';

/// The platform calls need a device, but the decisions around them — which
/// OS permission an Android version wants, and what a set of answers adds up
/// to — are pure and are where the bugs live.
void main() {
  group('which permission the gallery needs', () {
    test('Android 13+ asks for photos and videos, not storage', () {
      final perms = AppPermissions.galleryPermissionsFor(33);

      expect(perms, contains(Permission.photos));
      expect(perms, contains(Permission.videos));
      expect(perms, isNot(contains(Permission.storage)));
    });

    test('older Android asks for storage, which is all it has', () {
      final perms = AppPermissions.galleryPermissionsFor(30);

      expect(perms, [Permission.storage]);
    });

    test('iOS asks for photos regardless of any Android version', () {
      expect(AppPermissions.galleryPermissionsFor(0, isAndroid: false), [
        Permission.photos,
      ]);
    });
  });

  group('which permission Bluetooth needs', () {
    test('Android 12+ asks for the split scan/connect pair', () {
      final perms = AppPermissions.bluetoothPermissionsFor(31);

      expect(perms, contains(Permission.bluetoothScan));
      expect(perms, contains(Permission.bluetoothConnect));
    });

    test('older Android asks for the single legacy permission', () {
      final perms = AppPermissions.bluetoothPermissionsFor(30);

      expect(perms, [Permission.bluetooth]);
    });

    test('iOS has one Bluetooth permission, not the Android split', () {
      expect(AppPermissions.bluetoothPermissionsFor(0, isAndroid: false), [
        Permission.bluetooth,
      ]);
    });
  });

  group('combining the answers to a multi-permission ask', () {
    test('all granted is granted', () {
      expect(
        AppPermissions.combine([
          PermissionStatus.granted,
          PermissionStatus.granted,
        ]),
        PermissionOutcome.granted,
      );
    });

    test('limited counts as usable — iOS photo picking often is', () {
      expect(
        AppPermissions.combine([PermissionStatus.limited]),
        PermissionOutcome.granted,
      );
    });

    test('one refusal sinks the set', () {
      expect(
        AppPermissions.combine([
          PermissionStatus.granted,
          PermissionStatus.denied,
        ]),
        PermissionOutcome.denied,
      );
    });

    test('a permanent refusal outranks a temporary one', () {
      // The caller has to behave differently: only Settings fixes this.
      expect(
        AppPermissions.combine([
          PermissionStatus.denied,
          PermissionStatus.permanentlyDenied,
        ]),
        PermissionOutcome.permanentlyDenied,
      );
      expect(
        AppPermissions.combine([PermissionStatus.restricted]),
        PermissionOutcome.permanentlyDenied,
      );
    });

    test('nothing to ask for is not a refusal', () {
      // e.g. notifications below Android 13, where install implies the grant.
      expect(AppPermissions.combine(const []), PermissionOutcome.notApplicable);
    });
  });

  group('the outcome a caller acts on', () {
    test('only permanent refusal points at Settings', () {
      expect(PermissionOutcome.permanentlyDenied.needsSettings, isTrue);
      expect(PermissionOutcome.denied.needsSettings, isFalse);
      expect(PermissionOutcome.granted.needsSettings, isFalse);
    });

    test('notApplicable does not read as granted', () {
      // It means "no such gate here", so callers proceed — but they should
      // not be told a permission was granted that was never asked for.
      expect(PermissionOutcome.notApplicable.isGranted, isFalse);
    });
  });
}
