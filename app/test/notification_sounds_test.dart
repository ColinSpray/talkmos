import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkmos/core/notifications/notification_sounds.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('defaults', () {
    test(
      'messages fall back to the phone tone before anything is picked',
      () async {
        final setting = await NotificationSoundStore.messages.load();
        expect(setting.mode, SoundMode.system);
        expect(setting.displayName, 'Phone default');
      },
    );

    test('calls still fall back to the first bundled tune', () async {
      final setting = await NotificationSoundStore.calls.load();
      expect(setting.mode, SoundMode.bundled);
      expect(setting.displayName, 'Ringtone 1');
    });
  });

  group('systemDefault resolves without a URI', () {
    const setting = NotificationSoundSetting.systemDefault;

    test('carries no URI — the platform picks the tone', () {
      expect(setting.uri, isNull);
      expect(setting.androidSound, isNull);
    });

    test('still plays: a null sound is "phone default", not silence', () {
      expect(setting.playSound, isTrue);
    });

    test('silent is the only mode that suppresses sound', () {
      const silent = NotificationSoundSetting(mode: SoundMode.silent);
      expect(silent.playSound, isFalse);
      expect(silent.androidSound, isNull);
      // Both have a null sound — playSound is what separates them.
      expect(setting.androidSound, silent.androidSound);
      expect(setting.playSound, isNot(silent.playSound));
    });

    test('gets its own channel key, distinct from silent and from a URI', () {
      expect(setting.soundKey, 'sys_default');
      expect(
        setting.soundKey,
        isNot(const NotificationSoundSetting(mode: SoundMode.silent).soundKey),
      );
      expect(
        setting.soundKey,
        isNot(
          const NotificationSoundSetting(
            mode: SoundMode.system,
            uri: 'content://media/1',
          ).soundKey,
        ),
      );
    });
  });

  group('an explicitly picked tone still wins', () {
    test('a saved bundled choice survives the new message default', () async {
      await NotificationSoundStore.messages.save(
        const NotificationSoundSetting(
          mode: SoundMode.bundled,
          toneId: 'tone2',
        ),
      );
      final loaded = await NotificationSoundStore.messages.load();
      expect(loaded.mode, SoundMode.bundled);
      expect(loaded.displayName, 'Ringtone 2');
      expect(loaded.androidSound, isA<RawResourceAndroidNotificationSound>());
    });

    test('a saved silent choice is not overridden by the default', () async {
      await NotificationSoundStore.messages.save(
        const NotificationSoundSetting(mode: SoundMode.silent),
      );
      final loaded = await NotificationSoundStore.messages.load();
      expect(loaded.mode, SoundMode.silent);
      expect(loaded.playSound, isFalse);
    });

    test('a resolved phone-default URI round-trips with its title', () async {
      await NotificationSoundStore.messages.save(
        const NotificationSoundSetting(
          mode: SoundMode.system,
          uri: 'content://settings/system/notification_sound',
          title: 'Chime',
        ),
      );
      final loaded = await NotificationSoundStore.messages.load();
      expect(loaded.uri, 'content://settings/system/notification_sound');
      expect(loaded.displayName, 'Phone default (Chime)');
      expect(loaded.androidSound, isA<UriAndroidNotificationSound>());
    });
  });

  group('fromJson fallbacks are per-store', () {
    test('system mode with no URI is kept, not downgraded', () {
      final setting = NotificationSoundSetting.fromJson({
        'mode': 'system',
      }, fallback: NotificationSoundSetting.talkmosDefault);
      expect(setting.mode, SoundMode.system);
      expect(setting.playSound, isTrue);
    });

    test('custom mode with no URI names nothing, so it falls back', () {
      final setting = NotificationSoundSetting.fromJson({
        'mode': 'custom',
      }, fallback: NotificationSoundSetting.systemDefault);
      expect(setting.mode, SoundMode.system);
    });

    test('an unrecognised mode falls back to the store default', () {
      expect(
        NotificationSoundSetting.fromJson({
          'mode': 'nonsense',
        }, fallback: NotificationSoundSetting.systemDefault).mode,
        SoundMode.system,
      );
      expect(
        NotificationSoundSetting.fromJson({
          'mode': 'nonsense',
        }, fallback: NotificationSoundSetting.talkmosDefault).mode,
        SoundMode.bundled,
      );
    });

    test(
      'unreadable stored JSON falls back to the phone tone for messages',
      () async {
        SharedPreferences.setMockInitialValues({
          'message_sound_setting': 'not json at all',
        });
        final loaded = await NotificationSoundStore.messages.load();
        expect(loaded.mode, SoundMode.system);
      },
    );
  });
}
