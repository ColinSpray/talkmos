import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/titlecase_function.dart';
import 'call_foreground_service.dart';
import '../../../core/notifications/message_notifier.dart';
import '../../../core/notifications/notification_sounds.dart';
import 'call_activity_service.dart';

enum CallNotificationAction {
  accept,
  decline,
  open,
  hangUp,
  declinedInBackground,
}

enum CallNotificationKind { incoming, active }

class CallNotificationPayload {
  final String callId;
  final String callerId;
  final String callerName;
  final String callType;
  final CallNotificationKind kind;

  const CallNotificationPayload({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callType,
    this.kind = CallNotificationKind.incoming,
  });

  String encode() => jsonEncode({
    'callId': callId,
    'callerId': callerId,
    'callerName': callerName,
    'callType': callType,
    'kind': kind.name,
  });

  static CallNotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final callId = map['callId']?.toString() ?? '';
      if (callId.isEmpty) return null;
      return CallNotificationPayload(
        callId: callId,
        callerId: map['callerId']?.toString() ?? '',
        callerName: map['callerName']?.toString() ?? 'Someone',
        callType: map['callType']?.toString() ?? 'audio',
        kind: map['kind'] == 'active'
            ? CallNotificationKind.active
            : CallNotificationKind.incoming,
      );
    } catch (e) {
      debugPrint('[CallNotification] payload decode error: $e');
      return null;
    }
  }
}

class CallNotificationEvent {
  final CallNotificationAction action;
  final CallNotificationPayload payload;

  const CallNotificationEvent(this.action, this.payload);
}

/// Name the main isolate registers a [SendPort] under, so this isolate can
/// hand it an ending chosen from the shade — declined, or hung up.
const String _callEndedPortName = 'talkmos_call_ended_port';

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  if (response.actionId == MessageNotifier.replyActionId) {
    _handleBackgroundReply(response);
    return;
  }

  if (response.actionId == CallNotificationService.hangUpActionId) {
    _handleBackgroundHangUp(response);
    return;
  }

  if (response.actionId != CallNotificationService.declineActionId) return;
  final payload = CallNotificationPayload.decode(response.payload);
  if (payload == null) return;

  // Let the app (if it's running) drop its local ringing state. Fire-and-
  // forget: when the app is dead there's simply no port registered.
  try {
    IsolateNameServer.lookupPortByName(
      _callEndedPortName,
    )?.send(response.payload);
  } catch (_) {
    // A missing/stale port is expected when the app isn't running.
  }

  unawaited(_declineOverRest(payload.callId));
}

/// Hang Up, tapped while the app is off screen.
///
/// The app itself is usually still running — a call keeps a foreground
/// service up, which keeps the process alive — so the first choice is to hand
/// this to the isolate that owns the call: it leaves over the socket, stops
/// that service and takes the notification down. REST is the fallback for a
/// notification outliving the process that posted it.
void _handleBackgroundHangUp(NotificationResponse response) {
  final payload = CallNotificationPayload.decode(response.payload);
  if (payload == null) return;

  try {
    final port = IsolateNameServer.lookupPortByName(_callEndedPortName);
    if (port != null) {
      port.send(response.payload);
      return;
    }
  } catch (_) {
    // No port: the app is gone, so REST it is.
  }

  unawaited(_leaveOverRest(payload.callId));
}

void _handleBackgroundReply(NotificationResponse response) {
  final text = response.input?.trim();
  if (text == null || text.isEmpty) return;

  try {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['kind'] != 'chat') return;
    final chatId = map['chatId']?.toString() ?? '';
    if (chatId.isEmpty) return;
    // Replying answers everything in that thread — leaving it stored would
    // replay the answered messages under the next one to arrive.
    unawaited(MessageNotifier.clearFor(chatId));
    unawaited(_sendMessageReplyOverRest(chatId, text));
  } catch (e) {
    debugPrint('[CallNotification] reply payload decode error: $e');
  }
}

Future<void> _sendMessageReplyOverRest(String chatId, String text) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      debugPrint('[CallNotification] background reply: no auth token');
      return;
    }

    final response = await http
        .post(
          Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/messages'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'messageType': 'text', 'content': text}),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint('[CallNotification] background reply -> ${response.statusCode}');
  } catch (e) {
    debugPrint('[CallNotification] background reply failed: $e');
  }
}

Future<void> _leaveOverRest(String callId) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      debugPrint('[CallNotification] background hang-up: no auth token');
      return;
    }

    final response = await http
        .post(
          Uri.parse('${ApiConfig.callsUrl}/$callId/leave'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    debugPrint(
      '[CallNotification] background hang-up -> ${response.statusCode}',
    );
  } catch (e) {
    debugPrint('[CallNotification] background hang-up failed: $e');
  }
}

Future<void> _declineOverRest(String callId) async {
  try {
    // The background isolate starts with no plugin registrations and no
    // dotenv, so both have to be bootstrapped before anything else.
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      debugPrint('[CallNotification] background decline: no auth token');
      return;
    }

    final response = await http
        .post(
          Uri.parse('${ApiConfig.callsUrl}/$callId/decline'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    debugPrint(
      '[CallNotification] background decline -> ${response.statusCode}',
    );
  } catch (e) {
    debugPrint('[CallNotification] background decline failed: $e');
  }
}

class CallNotificationService {
  CallNotificationService._();

  static const int _incomingNotificationId = 991100;
  static const int _activeNotificationId = 991101;
  static const int _missedNotificationId = 991102;

  static const Duration ringTimeout = Duration(seconds: 30);
  static const String _channelIdPrefix = 'talkmos_incoming_calls_v2';
  static const String _activeChannelId = 'talkmos_active_calls';
  static const String _missedChannelId = 'talkmos_missed_calls';
  static const String _acceptActionId = 'accept';
  static const String _declineActionId = 'decline';
  static const String _hangUpActionId = 'hangup';

  static const Color _acceptGreen = Color(0xFF22C55E);
  static const Color _declineRed = Color(0xFFEF4444);

  /// Exposed so the background-isolate entry point (a top-level function,
  /// outside this class) can identify a Decline tap.
  static const String declineActionId = _declineActionId;
  static const String hangUpActionId = _hangUpActionId;

  static final FlutterLocalNotificationsPlugin _plugin = localNotifications;
  static final StreamController<CallNotificationEvent> _controller =
      StreamController<CallNotificationEvent>.broadcast();

  static Stream<CallNotificationEvent> get onEvent => _controller.stream;

  static void Function(String payload)? onOtherNotificationTap;

  static final ValueNotifier<bool> skipSplashReveal = ValueNotifier(false);

  static bool _isSetUp = false;

  /// Incoming-call channel. Its id encodes the chosen ringtone because
  /// Android freezes a channel's sound at creation.
  static SoundedChannel get incomingChannel => _incomingChannel;

  static const SoundedChannel _incomingChannel = SoundedChannel(
    idPrefix: _channelIdPrefix,
    name: 'Incoming Calls',
    description: 'Incoming voice and video calls',
    importance: Importance.max,
    usage: AudioAttributesUsage.notificationRingtone,
  );

  // ─── Ringtone selection ───────────────────────────────────────────────────

  /// The user's current call ringtone, defaulting to the bundled tune.
  static Future<NotificationSoundSetting> loadRingtone() =>
      NotificationSoundStore.calls.load();

  /// Stores [setting] and rebuilds the channel so the new tone takes effect.
  static Future<void> saveRingtone(NotificationSoundSetting setting) async {
    await NotificationSoundStore.calls.save(setting);
    await _incomingChannel.ensure(_plugin, setting);
  }

  static Future<String> _ensureIncomingChannel(
    NotificationSoundSetting setting,
  ) => _incomingChannel.ensure(_plugin, setting);

  static Future<void> setUp() async {
    if (_isSetUp) return;
    _isSetUp = true;

    _listenForBackgroundEndings();

    // Not the launcher icon: Android masks a small icon down to its alpha and
    // paints it white, and the launcher icon is fully opaque — it arrives as a
    // white square. ic_stat_talkmos is the same glyph on transparency.
    const androidInit = AndroidInitializationSettings('ic_stat_talkmos');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          MessageNotifier.replyCategoryId,
          actions: [
            DarwinNotificationAction.text(
              MessageNotifier.replyActionId,
              'Reply',
              buttonTitle: 'Send',
              placeholder: 'Message…',
            ),
          ],
        ),
      ],
    );

    try {
      await _plugin.initialize(
        settings: InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _handleResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationResponse,
      );

      await _ensureIncomingChannel(await loadRingtone());

      const activeChannel = AndroidNotificationChannel(
        _activeChannelId,
        'Active Calls',
        description: 'Ongoing voice and video calls',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(activeChannel);

      const missedChannel = AndroidNotificationChannel(
        _missedChannelId,
        'Missed Calls',
        description: 'Calls you did not answer',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(missedChannel);

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[CallNotification] setUp error: $e');
    }
  }

  /// Marks that the user has been asked for the full-screen-intent
  /// Whether an incoming call is allowed to take over the screen.
  ///
  /// Without this, Android 14+ downgrades the ring to a heads-up banner: the
  /// phone makes a noise, the screen stays dark, and unlocking it shows a
  /// notification rather than the call. It is the difference between a call
  /// you can answer and one you only hear.
  static const MethodChannel _fsiChannel = MethodChannel(
    'com.talkmos.app/full_screen_intent',
  );

  static Future<bool> canUseFullScreenIntent() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final allowed = await _fsiChannel.invokeMethod<bool>(
        'canUseFullScreenIntent',
      );
      return allowed ?? true;
    } catch (e) {
      // No handler (or an older Android): assume the older, unrestricted
      // behaviour rather than nagging about a permission that isn't real.
      debugPrint('[CallNotification] full-screen intent check failed: $e');
      return true;
    }
  }

  /// Sends the user to the system screen that grants it.
  static Future<void> requestFullScreenIntentPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestFullScreenIntentPermission();
    } catch (e) {
      debugPrint('[CallNotification] full-screen intent request failed: $e');
    }
  }

  static void _listenForBackgroundEndings() {
    try {
      IsolateNameServer.removePortNameMapping(_callEndedPortName);
      // The active listener below keeps this port alive for the life of the
      // isolate, so it doesn't need to be held in a field.
      final port = ReceivePort();
      IsolateNameServer.registerPortWithName(port.sendPort, _callEndedPortName);
      port.listen((dynamic raw) {
        final payload = CallNotificationPayload.decode(raw as String?);
        if (payload == null) return;
        // An ongoing call hung up from the shade, or a ringing one declined —
        // both end here, and both end the same way.
        _controller.add(
          CallNotificationEvent(
            payload.kind == CallNotificationKind.active
                ? CallNotificationAction.hangUp
                : CallNotificationAction.declinedInBackground,
            payload,
          ),
        );
      });
    } catch (e) {
      debugPrint('[CallNotification] call-ended port setup error: $e');
    }
  }

  static bool _launchDetailsConsumed = false;

  /// Identity of the last launch response acted on, persisted across VM
  /// restarts. See [consumeLaunchDetails] for why that matters.
  static const String _consumedLaunchKey = 'call_consumed_launch_payload';

  static Future<void> consumeLaunchDetails() async {
    if (_launchDetailsConsumed) return;
    _launchDetailsConsumed = true;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true ||
          details!.notificationResponse == null) {
        return;
      }

      final response = details.notificationResponse!;
      // Same intent can be reported repeatedly; key on the action + payload
      // so a genuinely new notification still gets through.
      final fingerprint = '${response.actionId ?? 'tap'}:${response.payload}';

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_consumedLaunchKey) == fingerprint) {
        debugPrint('[CallNotification] Launch response already handled.');
        return;
      }
      await prefs.setString(_consumedLaunchKey, fingerprint);

      _handleResponse(response);
    } catch (e) {
      debugPrint('[CallNotification] consumeLaunchDetails error: $e');
    }
  }

  static void _handleResponse(NotificationResponse response) {
    final payload = CallNotificationPayload.decode(response.payload);
    if (payload == null) {
      // Not a call notification — hand it to whoever owns that surface.
      final raw = response.payload;
      if (raw != null && raw.isNotEmpty) {
        onOtherNotificationTap?.call(raw);
      }
      return;
    }

    if (payload.kind == CallNotificationKind.active) {
      final action = response.actionId == _hangUpActionId
          ? CallNotificationAction.hangUp
          : CallNotificationAction.open;
      _controller.add(CallNotificationEvent(action, payload));
      return;
    }

    if (response.actionId == null) {
      CallActivityService.launchCallActivity(
        callId: payload.callId,
        callerId: payload.callerId,
        callerName: payload.callerName,
        callType: payload.callType,
      );
      return;
    }

    final action = response.actionId == _declineActionId
        ? CallNotificationAction.decline
        : CallNotificationAction.accept;
    _controller.add(CallNotificationEvent(action, payload));
  }

  // ─── Show / dismiss ────────────────────────────────────────────────────────

  static Future<void> showIncomingCall({
    required String callId,
    required String callerId,
    required String callerName,
    String callType = 'audio',
  }) async {
    try {
      final name = callerName.trim().isNotEmpty
          ? toTitleCase(callerName)
          : 'Unknown Caller';
      final payload = CallNotificationPayload(
        callId: callId,
        callerId: callerId,
        callerName: name,
        callType: callType,
        kind: CallNotificationKind.incoming,
      ).encode();

      final ringtone = await loadRingtone();
      final channelId = await _ensureIncomingChannel(ringtone);
      final sound = ringtone.androidSound;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'Incoming Calls',
        channelDescription: 'Incoming voice and video calls',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        timeoutAfter: ringTimeout.inMilliseconds + 5000,
        color: const Color(0xFF6852D6),
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
        playSound: ringtone.playSound,
        sound: sound,
        actions: const [
          AndroidNotificationAction(
            _declineActionId,
            'Decline',
            titleColor: _declineRed,
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _acceptActionId,
            'Accept',
            titleColor: _acceptGreen,
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'incoming_call',
        interruptionLevel: InterruptionLevel.timeSensitive,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.show(
        id: _incomingNotificationId,
        title: callType == 'video'
            ? 'Incoming video call'
            : 'Incoming voice call',
        body: name,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );
      debugPrint('[CallNotification] Showing notification for callId=$callId');
    } catch (e) {
      debugPrint('[CallNotification] showIncomingCall error: $e');
    }
  }

  /// Displays an ongoing, persistent notification for an active/connected call.
  /// Remains visible until the call is disconnected or ended.
  /// The shade's copy of a call in progress. [ringing] words it for a call
  /// that is still ringing out — the caller has nothing else to get back in
  /// by once they leave the call screen.
  static Future<void> showActiveCall({
    required String callId,
    required String peerName,
    String callType = 'audio',
    bool ringing = false,
  }) async {
    try {
      final name = peerName.trim().isNotEmpty
          ? toTitleCase(peerName)
          : 'TalkMos User';
      final payload = CallNotificationPayload(
        callId: callId,
        callerId: '',
        callerName: name,
        callType: callType,
        kind: CallNotificationKind.active,
      ).encode();

      await _plugin.cancel(id: _incomingNotificationId);
      // Before the notification: the service posts its own on the same id, and
      // whatever is shown last is what the user sees.
      await CallForegroundService.start();

      final androidDetails = AndroidNotificationDetails(
        _activeChannelId,
        'Active Calls',
        channelDescription: 'Ongoing voice and video calls',
        importance: Importance.low,
        priority: Priority.low,
        category: AndroidNotificationCategory.call,
        ongoing: true,
        autoCancel: false,
        playSound: false,
        color: const Color(0xFF0066FF),
        actions: const [
          AndroidNotificationAction(
            _hangUpActionId,
            'Hang Up',
            titleColor: _declineRed,
            // Hanging up is not a reason to throw the app on screen. It also
            // cannot cancel its own notification any more — the call
            // foreground service owns that id, and only stopping the service
            // takes it down (see endCall).
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'active_call',
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      await _plugin.show(
        id: _activeNotificationId,
        title: ringing
            ? (callType == 'video' ? 'Outgoing Video Call' : 'Outgoing Call')
            : (callType == 'video'
                  ? 'Ongoing Video Call'
                  : 'Ongoing Voice Call'),
        body: ringing
            ? (peerName.trim().isNotEmpty ? 'Calling $name…' : 'Calling…')
            : (peerName.trim().isNotEmpty
                  ? 'In call with $name'
                  : 'Call in progress'),
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );
      debugPrint(
        '[CallNotification] Showing active call notification for callId=$callId',
      );
    } catch (e) {
      debugPrint('[CallNotification] showActiveCall error: $e');
    }
  }

  static Future<void> showMissedCall({
    required String callerName,
    String callType = 'audio',
  }) async {
    try {
      final name = callerName.trim().isNotEmpty
          ? toTitleCase(callerName)
          : 'Unknown Caller';

      const androidDetails = AndroidNotificationDetails(
        _missedChannelId,
        'Missed Calls',
        channelDescription: 'Calls you did not answer',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.missedCall,
        color: Color(0xFF6852D6),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.show(
        id: _missedNotificationId,
        title: callType == 'video' ? 'Missed video call' : 'Missed voice call',
        body: name,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
      debugPrint('[CallNotification] Missed call notification for $name');
    } catch (e) {
      debugPrint('[CallNotification] showMissedCall error: $e');
    }
  }

  static Future<void> endCall(String callId) async {
    try {
      // First — an ongoing notification cannot be cancelled out from under a
      // foreground service that is still running on it.
      await CallForegroundService.stop();
      await _plugin.cancel(id: _incomingNotificationId);
      await _plugin.cancel(id: _activeNotificationId);
      CallActivityService.finishCallActivity();
    } catch (e) {
      debugPrint('[CallNotification] endCall error: $e');
    }
  }

  /// Same as [endCall] — kept as a separate name since callers reach for it
  /// on logout/reconnect without a specific callId in hand.
  static Future<void> endAllCalls() async {
    try {
      await CallForegroundService.stop();
      await _plugin.cancel(id: _incomingNotificationId);
      await _plugin.cancel(id: _activeNotificationId);
      CallActivityService.finishCallActivity();
    } catch (e) {
      debugPrint('[CallNotification] endAllCalls error: $e');
    }
  }
}
