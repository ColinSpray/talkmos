import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkmos/core/services/data_usage_store.dart';

void main() {
  final store = DataUsageStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store.reset();
    store.checkConnectivity = () async => [ConnectivityResult.wifi];
    await store.load();
  });

  group('recommended defaults', () {
    test(
      'upload quality matches what the picker sent before it was a setting',
      () {
        expect(store.uploadQuality, MediaUploadQuality.standard);
        expect(
          store.imageQuality,
          85,
          reason: 'an existing install must not silently change quality',
        );
      },
    );

    test('auto-save waits for Wi-Fi by default', () {
      expect(store.autoSaveWifiOnly, isTrue);
    });
  });

  group('upload quality', () {
    test('each option maps to a distinct image_picker quality', () {
      final qualities = MediaUploadQuality.values
          .map((q) => q.imageQuality)
          .toSet();
      expect(qualities.length, MediaUploadQuality.values.length);
      expect(
        MediaUploadQuality.dataSaver.imageQuality,
        lessThan(MediaUploadQuality.high.imageQuality),
      );
    });

    test('survives a reload', () async {
      await store.setUploadQuality(MediaUploadQuality.high);
      store.reset();
      await store.load();
      expect(store.uploadQuality, MediaUploadQuality.high);
      expect(store.imageQuality, 95);
    });

    test('an unknown stored value falls back to standard', () async {
      SharedPreferences.setMockInitialValues({
        DataUsageStore.keyUploadQuality: 'ultra-max-not-a-real-option',
      });
      store.reset();
      await store.load();
      expect(store.uploadQuality, MediaUploadQuality.standard);
    });
  });

  group('canAutoDownloadNow', () {
    test('allows anything when the restriction is off', () async {
      await store.setAutoSaveWifiOnly(false);
      store.checkConnectivity = () async => [ConnectivityResult.mobile];
      expect(await store.canAutoDownloadNow(), isTrue);
    });

    test('allows Wi-Fi', () async {
      store.checkConnectivity = () async => [ConnectivityResult.wifi];
      expect(await store.canAutoDownloadNow(), isTrue);
    });

    test('allows ethernet — also unmetered', () async {
      store.checkConnectivity = () async => [ConnectivityResult.ethernet];
      expect(await store.canAutoDownloadNow(), isTrue);
    });

    test('blocks mobile data', () async {
      store.checkConnectivity = () async => [ConnectivityResult.mobile];
      expect(await store.canAutoDownloadNow(), isFalse);
    });

    test('blocks when offline', () async {
      store.checkConnectivity = () async => [ConnectivityResult.none];
      expect(await store.canAutoDownloadNow(), isFalse);
    });

    test('allows a Wi-Fi + VPN combination', () async {
      // Both are reported together on a VPN over Wi-Fi; the connection is
      // still unmetered, so blocking it would be wrong.
      store.checkConnectivity = () async => [
        ConnectivityResult.vpn,
        ConnectivityResult.wifi,
      ];
      expect(await store.canAutoDownloadNow(), isTrue);
    });

    test('a failing connectivity check blocks rather than allows', () async {
      store.checkConnectivity = () async => throw Exception('platform error');

      // The restriction exists to prevent surprise data charges, so the
      // unknown case has to fall on the cautious side.
      expect(await store.canAutoDownloadNow(), isFalse);
    });

    test('a failing check still allows when the restriction is off', () async {
      await store.setAutoSaveWifiOnly(false);
      store.checkConnectivity = () async => throw Exception('platform error');

      // Short-circuits before ever asking, so a broken platform channel can't
      // disable auto-save for someone who never opted into the restriction.
      expect(await store.canAutoDownloadNow(), isTrue);
    });
  });
}
