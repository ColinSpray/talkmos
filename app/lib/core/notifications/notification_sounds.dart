import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

/// Where a notification/ringtone sound comes from.
enum SoundMode {
  /// One of the tones shipped in `android/app/src/main/res/raw/`.
  bundled,

  /// The phone's current default ringtone.
  system,

  /// A specific tone the user picked from the system ringtone picker.
  custom,

  /// No sound at all.
  silent,
}

class BundledTone {
  final String id;
  final String displayName;

  /// `res/raw` filename without extension.
  final String rawResource;

  const BundledTone({
    required this.id,
    required this.displayName,
    required this.rawResource,
  });
}

class BundledTones {
  const BundledTones._();

  static const BundledTone tone1 = BundledTone(
    id: 'tone1',
    displayName: 'Ringtone 1',
    rawResource: 'talkmos_tone_1',
  );

  static const BundledTone tone2 = BundledTone(
    id: 'tone2',
    displayName: 'Ringtone 2',
    rawResource: 'talkmos_tone_2',
  );

  static const List<BundledTone> all = [tone1, tone2];

  /// Anything unrecognised — including tone ids from before they were named —
  /// resolves to the first tone rather than to a missing raw resource.
  static BundledTone byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => tone1);
}

/// A resolved sound choice, persisted per purpose (calls vs messages).
@immutable
class NotificationSoundSetting {
  final SoundMode mode;

  /// Which [BundledTone] when [mode] is [SoundMode.bundled].
  final String? toneId;

  /// Content URI for [SoundMode.system] / [SoundMode.custom].
  final String? uri;

  /// Cached display name so settings can render without a platform call.
  final String? title;

  const NotificationSoundSetting({
    required this.mode,
    this.toneId,
    this.uri,
    this.title,
  });

  static const NotificationSoundSetting talkmosDefault =
      NotificationSoundSetting(mode: SoundMode.bundled, toneId: 'tone1');

  static const NotificationSoundSetting systemDefault =
      NotificationSoundSetting(mode: SoundMode.system);

  String get displayName {
    switch (mode) {
      case SoundMode.bundled:
        return BundledTones.byId(toneId).displayName;
      case SoundMode.system:
        return title?.isNotEmpty == true
            ? 'Phone default ($title)'
            : 'Phone default';
      case SoundMode.custom:
        return title?.isNotEmpty == true ? title! : 'Custom';
      case SoundMode.silent:
        return 'Silent';
    }
  }

  String get soundKey {
    switch (mode) {
      case SoundMode.bundled:
        return 'r_${BundledTones.byId(toneId).rawResource}';
      case SoundMode.silent:
        return 'silent';
      case SoundMode.system:
      case SoundMode.custom:
        final resolved = uri;
        if (resolved == null || resolved.isEmpty) return 'sys_default';
        return 'u_${resolved.hashCode.toUnsigned(32).toRadixString(16)}';
    }
  }

  bool get playSound => mode != SoundMode.silent;

  AndroidNotificationSound? get androidSound {
    switch (mode) {
      case SoundMode.bundled:
        return RawResourceAndroidNotificationSound(
          BundledTones.byId(toneId).rawResource,
        );
      case SoundMode.system:
      case SoundMode.custom:
        final resolved = uri;
        if (resolved == null || resolved.isEmpty) return null;
        return UriAndroidNotificationSound(resolved);
      case SoundMode.silent:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'toneId': toneId,
    'uri': uri,
    'title': title,
  };

  static NotificationSoundSetting fromJson(
    Map<String, dynamic> json, {
    NotificationSoundSetting fallback = talkmosDefault,
  }) {
    final mode = SoundMode.values.firstWhere(
      (m) => m.name == json['mode']?.toString(),
      orElse: () => fallback.mode,
    );
    final uri = json['uri']?.toString();
    if (mode == SoundMode.custom && (uri == null || uri.isEmpty)) {
      return fallback;
    }
    return NotificationSoundSetting(
      mode: mode,
      toneId: json['toneId']?.toString(),
      uri: uri,
      title: json['title']?.toString(),
    );
  }
}

class NotificationSoundStore {
  final String prefsKey;

  /// What [load] returns before the user has chosen anything, and whatever it
  /// falls back to when the stored value can't be read.
  final NotificationSoundSetting fallback;

  const NotificationSoundStore(this.prefsKey, {required this.fallback});

  /// Calls keep the bundled tune: an incoming call should sound like this app
  /// rather than like every other notification on the phone.
  static const NotificationSoundStore calls = NotificationSoundStore(
    'call_ringtone_setting',
    fallback: NotificationSoundSetting.talkmosDefault,
  );

  static const NotificationSoundStore messages = NotificationSoundStore(
    'message_sound_setting',
    fallback: NotificationSoundSetting.systemDefault,
  );

  Future<NotificationSoundSetting> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The FCM isolate that rings an incoming call keeps its own prefs cache
      // for as long as the process lives, so without this it goes on ringing
      // with whatever tone was set when it started.
      await prefs.reload();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return fallback;
      return NotificationSoundSetting.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        fallback: fallback,
      );
    } catch (e) {
      debugPrint('[Sounds] load($prefsKey) failed: $e');
      return fallback;
    }
  }

  Future<void> save(NotificationSoundSetting setting) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(setting.toJson()));
    } catch (e) {
      debugPrint('[Sounds] save($prefsKey) failed: $e');
    }
  }
}

/// Creates notification channels whose id encodes their sound, and retires the
/// ones left behind by previous choices.
class SoundedChannel {
  final String idPrefix;
  final String name;
  final String description;
  final Importance importance;
  final AudioAttributesUsage usage;

  const SoundedChannel({
    required this.idPrefix,
    required this.name,
    required this.description,
    required this.importance,
    required this.usage,
  });

  String channelIdFor(NotificationSoundSetting setting) =>
      '${idPrefix}_${setting.soundKey}';

  Future<String> ensure(
    FlutterLocalNotificationsPlugin plugin,
    NotificationSoundSetting setting, {
    bool enableVibration = true,
  }) async {
    final channelId = channelIdFor(setting);
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return channelId;

    try {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          name,
          description: description,
          importance: importance,
          // Not `sound != null`: a null sound on a non-silent mode means
          // "the phone's own tone", which needs playSound to stay true.
          playSound: setting.playSound,
          sound: setting.androidSound,
          audioAttributesUsage: usage,
          enableVibration: enableVibration,
        ),
      );

      // Drop channels from earlier sound choices so the system settings list
      // doesn't accumulate a duplicate per tone the user has tried.
      final existing = await android.getNotificationChannels();
      for (final channel in existing ?? <AndroidNotificationChannel>[]) {
        final id = channel.id;
        final isOurs = id == idPrefix || id.startsWith('${idPrefix}_');
        if (isOurs && id != channelId) {
          await android.deleteNotificationChannel(channelId: id);
        }
      }
    } catch (e) {
      debugPrint('[Sounds] ensure($idPrefix) failed: $e');
    }
    return channelId;
  }
}
