import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkmos/core/encryption/chat_encryption.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';

import '../../features/auth/services/auth_service.dart';
import '../../features/calls/services/call_notification_service.dart';
import '../../features/chats/screens/chat_screen/chat_screen.dart';
import '../../features/chats/services/chat_service/chat_service.dart';
import '../../features/nearby/services/nearby_locate_responder.dart';
import '../../features/users/screens/friend_requests_screen.dart';
import '../../features/users/services/blocked_users_store.dart';
import '../../models/user_model.dart';
import '../services/navigation_service.dart';
import 'message_notifier.dart';
import 'muted_chats_store.dart';

const _kFriendRequestTypes = {'friend_request', 'friend_request_accepted'};

// ─── Background / killed-state handler ───────────────────────────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[FCM Background] Firebase init error: $e');
  }

  if (!dotenv.isInitialized) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('[FCM Background] dotenv load failed: $e');
    }
  }

  debugPrint('[FCM Background] Message received: ${message.messageId}');

  final data = message.data;
  try {
    switch (data['type']) {
      case 'call':
        await _showIncomingCall(data);
      case 'call_ended':
        // Our socket missed the live broadcast — cancelling an already-gone
        // notification is a harmless no-op.
        await CallNotificationService.endAllCalls();
      case 'system':
        await _showGeneralNotification(data, 'system');
      case NearbyLocateResponder.messageType:
        await NearbyLocateResponder.handle();
      case final String type when _kFriendRequestTypes.contains(type):
        await _showGeneralNotification(data, type);
      default:
        await _showMessageNotification(data);
        final messageId = data['messageId'];
        if (messageId != null && messageId.isNotEmpty) {
          await ChatService().markDelivered(messageId);
        }
    }
  } catch (e) {
    debugPrint('[FCM Background] Processing failed: $e');
  }
}

Future<void> _showIncomingCall(Map<String, dynamic> data) async {
  final callId = data['callId'];
  if (callId == null || callId.isEmpty) return;

  final initiatorId = data['initiatorId'] ?? '';
  if (await BlockedUsersStore.isBlockedOnDisk(initiatorId)) {
    debugPrint('[FCM Background] Call from blocked user $initiatorId');
    return;
  }

  await CallNotificationService.showIncomingCall(
    callId: callId,
    callerId: initiatorId,
    callerName: toTitleCase(data['initiatorName'] ?? 'Someone'),
    callType: data['callType'] ?? 'audio',
  );
  debugPrint('[FCM Background] FSI shown for callId=$callId');
}

/// Renders a chat-message push. Shared by the background isolate and the
/// foreground listener, so prefs are read straight off disk.
Future<void> _showMessageNotification(Map<String, dynamic> data) async {
  try {
    final chatId = data['chatId']?.toString() ?? '';
    if (chatId.isEmpty) return;

    final senderId = data['senderId']?.toString() ?? '';
    if (await BlockedUsersStore.isBlockedOnDisk(senderId)) {
      debugPrint(
        '[FCM] Suppressed message notification from blocked $senderId',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // Same reason as NotificationSoundStore.load(): these are written by the
    // app, read here in the push isolate, which caches them.
    await prefs.reload();
    if (prefs.getBool('settings_receive_notifications') == false) return;
    if (await MutedChatsStore.isMuted(chatId)) return;

    await MessageNotifier.show(
      chatId: chatId,
      senderId: senderId,
      senderName: toTitleCase(data['senderName']?.toString() ?? ''),
      avatarUrl: data['senderAvatar']?.toString() ?? '',
      body: await _messagePreviewText(data, chatId: chatId, senderId: senderId),
      showPreview: prefs.getBool('settings_show_preview') ?? true,
      vibrate: prefs.getBool('settings_vibrate') ?? true,
    );
  } catch (e) {
    debugPrint('[FCM] Failed to show message notification: $e');
  }
}

/// The line to show for a message push. Chat content travels encrypted — the
/// server only ever stores the ciphertext — so the plaintext has to be
/// recovered here, from a key the push itself identifies. Anything that
/// can't be decrypted (media messages carry no text at all) falls back to the
/// server's own description, e.g. "Sent a photo".
Future<String> _messagePreviewText(
  Map<String, dynamic> data, {
  required String chatId,
  required String senderId,
}) async {
  final fallback = data['body']?.toString() ?? '';
  final cipherText = data['content']?.toString() ?? '';
  if (cipherText.isEmpty || senderId.isEmpty || chatId.isEmpty) return fallback;

  // Same entry point the chat itself decrypts through, so the notification
  // can't drift onto its own scheme. It hands back the input unchanged when
  // it fails, which is exactly the case that needs the fallback.
  final plain = await ChatEncryption.instance.decryptContent(
    cipherText,
    senderId: senderId,
    chatId: chatId,
  );
  if (plain.trim().isEmpty || plain == cipherText) return fallback;
  return plain;
}

/// Renders a non-chat push (friend requests, admin broadcasts).
Future<void> _showGeneralNotification(
  Map<String, dynamic> data,
  String type,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('settings_receive_notifications') == false) return;

    final title = data['title']?.toString() ?? 'Talkmos';
    final body = data['body']?.toString() ?? '';
    if (body.isEmpty) return;

    // Keyed by request id so a repeat push replaces rather than stacks.
    // Broadcasts carry no such id, so those key by content instead.
    final tag = type == 'system'
        ? 'system:${title.hashCode}:${body.hashCode}'
        : '$type:${data['friendRequestId'] ?? ''}';

    await MessageNotifier.showGeneral(
      tag: tag,
      type: type,
      title: title,
      body: body,
      imageUrl: data['imageUrl']?.toString(),
      vibrate: prefs.getBool('settings_vibrate') ?? true,
    );
  } catch (e) {
    debugPrint('[FCM] Failed to show general notification: $e');
  }
}

// ─── NotificationService ─────────────────────────────────────────────────────

class NotificationService {
  final AuthService _authService = AuthService();

  String? _fcmToken;
  bool _isFirebaseInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  Future<void> initialize() async {
    if (_isFirebaseInitialized) return;

    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        // Lets a call ring over DND on iOS.
        criticalAlert: true,
      );
      debugPrint('Notification permission: ${settings.authorizationStatus}');

      _fcmToken = await messaging.getToken();
      messaging.onTokenRefresh.listen((newToken) => _fcmToken = newToken);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Cold start — the app was opened by tapping a notification.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _handleNotificationClick(initialMessage);

      CallNotificationService.onOtherNotificationTap = _handleLocalTap;

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint('Firebase init failed/skipped: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM Foreground] Message: ${message.messageId}');
    final data = message.data;

    switch (data['type']) {
      case 'call':
        await _showForegroundCall(data);
      case 'call_ended':
        await CallNotificationService.endAllCalls();
      case 'system':
        await _showGeneralNotification(data, 'system');
      case NearbyLocateResponder.messageType:
        await NearbyLocateResponder.handle();
      case final String type when _kFriendRequestTypes.contains(type):
        // Delivered live over the socket (FriendProvider), so the push itself
        // has nothing left to do.
        debugPrint('[FCM Foreground] Friend request notification: $type');
      default:
        if (MessageNotifier.activeChatId != data['chatId']?.toString()) {
          await _showMessageNotification(data);
        }
        final messageId = data['messageId'];
        if (messageId != null && messageId.isNotEmpty) {
          try {
            await ChatService().markDelivered(messageId);
          } catch (e) {
            debugPrint('[FCM] Delivery report failed: $e');
          }
        }
    }
  }

  /// The socket's `incoming_call` event drives the in-app popup, so CallKit
  /// only fires when the app is not actually on screen.
  Future<void> _showForegroundCall(Map<String, dynamic> data) async {
    if (await BlockedUsersStore.isBlockedOnDisk(data['initiatorId'] ?? '')) {
      debugPrint('[FCM Foreground] Call from blocked user ignored');
      return;
    }

    final callId = data['callId'];
    if (callId == null || callId.isEmpty) return;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }

    await CallNotificationService.showIncomingCall(
      callId: callId,
      callerId: data['initiatorId'] ?? '',
      callerName: data['initiatorName'] ?? 'Someone',
      callType: data['callType'] ?? 'audio',
    );
  }

  /// A tap on a notification this app drew itself. The payload is the JSON
  /// encoded in [MessageNotifier].
  void _handleLocalTap(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final kind = map['kind']?.toString() ?? '';
      if (kind == 'chat') {
        _openChat(
          chatId: map['chatId']?.toString(),
          senderId: map['senderId']?.toString(),
          senderName: map['senderName']?.toString() ?? 'Chat',
        );
      } else if (_kFriendRequestTypes.contains(kind)) {
        _openFriendRequests(kind);
      }
    } catch (e) {
      debugPrint('[FCM] Local notification tap parse failed: $e');
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    if (type == 'call') {
      // Accept/Decline are handled by CallNotificationService.onEvent in
      // MainNavigationContainer; a body tap arrives on the callkit stream too.
      debugPrint('[FCM] Call notification tapped. callId=${data['callId']}');
    } else if (_kFriendRequestTypes.contains(type)) {
      _openFriendRequests(type);
    } else {
      _openChat(
        chatId: data['chatId'] as String?,
        senderId: data['senderId'] as String?,
        senderName: data['senderName'] as String? ?? 'Chat',
      );
    }
  }

  /// The delay lets the app finish restoring before a route is pushed on top.
  void _openChat({
    String? chatId,
    String? senderId,
    String senderName = 'Chat',
  }) {
    if (chatId == null || senderId == null) return;
    final context = NavigationService.context;
    if (context == null) return;

    final peerUser = UserModel(
      id: senderId,
      name: senderName,
      username: '',
      avatarUrl: '',
      bio: '',
      location: '',
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            activeUser: peerUser,
            chatId: chatId,
            chatType: 'direct',
          ),
        ),
      );
    });
  }

  /// A new incoming request lands on "Pending" so it can be acted on; an
  /// acceptance lands on "My Friends" where the new friend now shows.
  void _openFriendRequests(String type) {
    final context = NavigationService.context;
    if (context == null) return;
    Future.delayed(const Duration(milliseconds: 600), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FriendRequestsScreen(
            initialTabIndex: type == 'friend_request' ? 1 : 0,
          ),
        ),
      );
    });
  }

  Future<bool> uploadToken(String fcmToken) async {
    final success = await _authService.updateFcmToken(fcmToken);
    debugPrint('[FCM] Token sync ${success ? 'succeeded' : 'failed'}.');
    return success;
  }
}
