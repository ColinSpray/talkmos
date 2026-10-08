import 'package:shared_preferences/shared_preferences.dart';

class MutedChatsStore {
  const MutedChatsStore._();

  static const _key = 'muted_chat_ids';

  static Future<bool> isMuted(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).contains(chatId);
  }

  static Future<void> sync(Iterable<String> mutedChatIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, mutedChatIds.toSet().toList());
  }
}
