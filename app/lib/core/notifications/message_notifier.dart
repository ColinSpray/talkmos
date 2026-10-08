import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'notification_avatar.dart';
import 'notification_sounds.dart';
import 'notification_thread_store.dart';

class _DownloadedImage {
  final Uint8List bytes;
  final String filePath;
  const _DownloadedImage(this.bytes, this.filePath);
}

Future<_DownloadedImage?> _downloadNotificationImage(String url) async {
  try {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final bytes = response.bodyBytes;

    // iOS attachments must be a file on disk — there's no bytes-in-memory API.
    final dir = await getTemporaryDirectory();
    final ext = url.toLowerCase().contains('.png') ? 'png' : 'jpg';
    final file = File(
      '${dir.path}/notif_image_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await file.writeAsBytes(bytes);

    return _DownloadedImage(bytes, file.path);
  } catch (e) {
    debugPrint('[MessageNotifier] image download failed: $e');
    return null;
  }
}

class MessageNotifier {
  const MessageNotifier._();

  static const String channelIdPrefix = 'talkmos_messages';

  static const String replyActionId = 'reply';

  /// iOS category carrying the text-input reply action — registered once at
  /// plugin init time and referenced by [show] on every message notification.
  static const String replyCategoryId = 'message_reply';

  /// Chat currently open on screen, if any. Set by ChatScreen so foreground
  /// pushes for the conversation being read don't fire a notification.
  static String? activeChatId;

  static const SoundedChannel _channel = SoundedChannel(
    idPrefix: channelIdPrefix,
    name: 'Messages',
    description: 'New chat messages',
    importance: Importance.high,
    usage: AudioAttributesUsage.notification,
  );

  static SoundedChannel get channel => _channel;

  /// Stable per-chat id: one notification per conversation, carrying every
  /// unread line (see [NotificationThreadStore]).
  static int _notificationIdFor(String chatId) => chatId.hashCode & 0x7fffffff;

  /// Bundles every chat notification under one group, so several
  /// conversations stack instead of competing for the shade.
  static const String _groupKey = 'com.talkmos.app.MESSAGES';

  static const int _summaryId = 991200;

  /// Shows a message notification. [showPreview] false collapses the content
  /// to a generic line, matching the user's preview preference.
  ///
  /// [avatarUrl] is the sender's photo; without one Android falls back to its
  /// own initial-based avatar.
  static Future<void> show({
    required String chatId,
    required String senderId,
    required String senderName,
    required String body,
    String avatarUrl = '',
    bool showPreview = true,
    bool vibrate = true,
  }) async {
    try {
      final setting = await NotificationSoundStore.messages.load();
      // Created here rather than assumed, because this also runs in the FCM
      // background isolate where nothing has been set up yet.
      final channelId = await _channel.ensure(
        localNotifications,
        setting,
        enableVibration: vibrate,
      );
      final sound = setting.androidSound;

      final title = showPreview
          ? (senderName.isNotEmpty ? senderName : 'New message')
          : 'New message';
      final content = showPreview && body.isNotEmpty
          ? body
          : 'You have a new message';

      final thread = await NotificationThreadStore.append(
        chatId,
        NotifiedMessage(
          senderId: senderId,
          senderName: title,
          text: content,
          timestamp: DateTime.now(),
          avatarUrl: showPreview ? avatarUrl : '',
        ),
      );

      // One Person per sender so a group chat attributes its lines to the
      // right name and face.
      final people = <String, Person>{};
      for (final message in thread) {
        final key = '${message.senderId}|${message.senderName}';
        if (people.containsKey(key)) continue;
        final photo = await notificationAvatar(message.avatarUrl);
        people[key] = Person(
          key: message.senderId.isNotEmpty ? message.senderId : null,
          name: message.senderName,
          icon: photo != null ? ByteArrayAndroidIcon(photo) : null,
        );
      }

      // The collapsed notification doesn't use the Person icons.
      final largeIcon = await notificationAvatar(showPreview ? avatarUrl : '');

      await localNotifications.show(
        id: _notificationIdFor(chatId),
        title: title,
        body: content,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Messages',
            channelDescription: 'New chat messages',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.message,
            enableVibration: vibrate,
            playSound: setting.playSound,
            sound: sound,
            groupKey: _groupKey,
            largeIcon: largeIcon != null
                ? ByteArrayAndroidBitmap(largeIcon)
                : null,
            // Messaging style keeps every unread line from the conversation
            // visible; BigText could only ever show the newest one.
            styleInformation: MessagingStyleInformation(
              const Person(name: 'You'),
              groupConversation: false,
              messages: [
                for (final message in thread)
                  Message(
                    message.text,
                    message.timestamp,
                    people['${message.senderId}|${message.senderName}'],
                  ),
              ],
            ),
            actions: const <AndroidNotificationAction>[
              AndroidNotificationAction(
                replyActionId,
                'Reply',
                showsUserInterface: false,
                cancelNotification: true,
                inputs: [AndroidNotificationActionInput(label: 'Message')],
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: replyCategoryId,
            threadIdentifier: 'talkmos_messages',
          ),
        ),
        // Taps are delivered by flutter_local_notifications, not FCM, so the
        // payload must carry everything the chat route needs.
        payload: jsonEncode({
          'kind': 'chat',
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName,
        }),
      );

      await _showGroupSummary(channelId);
    } catch (e) {
      debugPrint('[MessageNotifier] show failed: $e');
    }
  }

  /// Android only bundles a group once it has a summary to bundle under.
  static Future<void> _showGroupSummary(String channelId) async {
    try {
      final chats = await NotificationThreadStore.activeChats();
      if (chats.length < 2) {
        await localNotifications.cancel(id: _summaryId);
        return;
      }

      await localNotifications.show(
        id: _summaryId,
        title: 'Talkmos',
        body: '${chats.length} conversations',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Messages',
            channelDescription: 'New chat messages',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.message,
            groupKey: _groupKey,
            setAsGroupSummary: true,
            // The individual notifications already made their noise.
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[MessageNotifier] summary failed: $e');
    }
  }

  static Future<void> showGeneral({
    required String tag,
    required String type,
    required String title,
    required String body,
    String? imageUrl,
    bool vibrate = true,
  }) async {
    try {
      final setting = await NotificationSoundStore.messages.load();
      final channelId = await _channel.ensure(
        localNotifications,
        setting,
        enableVibration: vibrate,
      );
      final sound = setting.androidSound;

      final image = (imageUrl != null && imageUrl.isNotEmpty)
          ? await _downloadNotificationImage(imageUrl)
          : null;

      await localNotifications.show(
        id: tag.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Messages',
            channelDescription: 'New chat messages',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: vibrate,
            // See the note in [show] — needed for API 24/25, ignored above it.
            playSound: setting.playSound,
            sound: sound,
            styleInformation: image != null
                ? BigPictureStyleInformation(
                    ByteArrayAndroidBitmap(image.bytes),
                    summaryText: body,
                    showBigPictureWhenCollapsed: true,
                    hideExpandedLargeIcon: true,
                  )
                : BigTextStyleInformation(body),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            attachments: image != null
                ? [DarwinNotificationAttachment(image.filePath)]
                : null,
          ),
        ),
        payload: jsonEncode({'kind': type}),
      );
    } catch (e) {
      debugPrint('[MessageNotifier] showGeneral failed: $e');
    }
  }

  /// Clears the notification for a chat — used when the user opens it.
  static Future<void> clearFor(String chatId) async {
    try {
      await localNotifications.cancel(id: _notificationIdFor(chatId));
      final remaining = await NotificationThreadStore.clear(chatId);
      // A summary left standing alone shows as an empty "Talkmos" bundle.
      if (remaining < 2) await localNotifications.cancel(id: _summaryId);
    } catch (e) {
      debugPrint('[MessageNotifier] clear failed: $e');
    }
  }
}
