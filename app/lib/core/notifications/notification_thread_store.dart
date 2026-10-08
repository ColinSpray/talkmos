import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One line of a chat's notification thread.
@immutable
class NotifiedMessage {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  /// Sender photo, kept per line so an older line in a group chat keeps the
  /// face it arrived with.
  final String avatarUrl;

  const NotifiedMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.avatarUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'i': senderId,
    'n': senderName,
    't': text,
    'ts': timestamp.millisecondsSinceEpoch,
    'a': avatarUrl,
  };

  static NotifiedMessage fromJson(Map<String, dynamic> json) => NotifiedMessage(
    senderId: json['i']?.toString() ?? '',
    senderName: json['n']?.toString() ?? '',
    text: json['t']?.toString() ?? '',
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      (json['ts'] as num?)?.toInt() ?? 0,
    ),
    avatarUrl: json['a']?.toString() ?? '',
  );
}

/// Keeps the recent messages behind each chat's notification, so a second
/// message adds a line to the conversation instead of replacing the first.
///
/// Lives on disk because most notifications are built in the FCM background
/// isolate, which starts empty every time and shares nothing with the app.
class NotificationThreadStore {
  const NotificationThreadStore._();

  static const String _prefsKey = 'notification_threads';

  /// How many lines Android's messaging style is worth showing before the
  /// rest is just noise.
  static const int _maxPerChat = 6;

  /// Threads older than this are a new conversation, not a continuation.
  static const Duration _staleAfter = Duration(hours: 12);

  static Future<Map<String, List<NotifiedMessage>>> _readAll(
    SharedPreferences prefs,
  ) async {
    try {
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cutoff = DateTime.now().subtract(_staleAfter);
      final out = <String, List<NotifiedMessage>>{};
      decoded.forEach((chatId, value) {
        final messages = (value as List<dynamic>)
            .map((e) => NotifiedMessage.fromJson(e as Map<String, dynamic>))
            .where((m) => m.timestamp.isAfter(cutoff))
            .toList();
        if (messages.isNotEmpty) out[chatId] = messages;
      });
      return out;
    } catch (e) {
      debugPrint('[NotifThreads] read failed: $e');
      return {};
    }
  }

  static Future<void> _writeAll(
    SharedPreferences prefs,
    Map<String, List<NotifiedMessage>> threads,
  ) async {
    try {
      await prefs.setString(
        _prefsKey,
        jsonEncode(
          threads.map(
            (chatId, messages) =>
                MapEntry(chatId, messages.map((m) => m.toJson()).toList()),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotifThreads] write failed: $e');
    }
  }

  /// Adds [message] to [chatId]'s thread and returns the thread to render.
  static Future<List<NotifiedMessage>> append(
    String chatId,
    NotifiedMessage message,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // The app and the background isolate each cache prefs, so the other
    // side's writes are only visible after a reload.
    await prefs.reload();
    final threads = await _readAll(prefs);
    final thread = [...?threads[chatId], message];
    final trimmed = thread.length > _maxPerChat
        ? thread.sublist(thread.length - _maxPerChat)
        : thread;
    threads[chatId] = trimmed;
    await _writeAll(prefs, threads);
    return trimmed;
  }

  /// Chat ids that still have a notification thread, newest activity first.
  static Future<List<String>> activeChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final threads = await _readAll(prefs);
    final ids = threads.keys.toList();
    ids.sort((a, b) {
      final at = threads[a]!.last.timestamp;
      final bt = threads[b]!.last.timestamp;
      return bt.compareTo(at);
    });
    return ids;
  }

  /// Forgets [chatId]'s thread — the user has read it. Returns how many chats
  /// still have one.
  static Future<int> clear(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final threads = await _readAll(prefs);
    threads.remove(chatId);
    await _writeAll(prefs, threads);
    return threads.length;
  }
}
