import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/features/users/services/blocked_users_store.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/models/home_summary_model.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/models/recent_chat.dart';
import 'package:talkmos/core/notifications/muted_chats_store.dart';
import 'package:talkmos/core/services/file_naming_service.dart';
import 'package:talkmos/core/services/data_usage_store.dart';
import 'package:talkmos/core/services/gallery_save_service.dart';
import 'package:talkmos/core/services/media_cache_service.dart';
import 'package:talkmos/core/services/media_visibility_store.dart';
import 'package:talkmos/core/translation/app_language.dart';
import 'package:talkmos/core/translation/translation_service.dart';
import 'package:talkmos/core/database/offline_message_store.dart';
import 'package:talkmos/core/database/database_helper.dart';
import 'package:talkmos/core/encryption/chat_encryption.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService chatService;
  final SocketService socketService;
  final OfflineMessageStore _offlineStore = OfflineMessageStore.instance;
  final ChatEncryption _encryption = ChatEncryption.instance;

  Map<String, List<ChatMessageModel>> messages = {};
  Map<String, dynamic> activeChatDetails = {};
  UserModel? user;
  bool isLoadingChats = false;
  final Set<String> _loadingMessageChats = {};

  bool isLoadingMessagesFor(String chatId) =>
      _loadingMessageChats.contains(chatId);
  String? activeChatId;
  Map<String, Set<String>> typingUsers = {};
  List<RecentChat> recentChats = [];
  List<RecentChat> archivedChats = [];
  bool isLoadingArchivedChats = false;
  HomeSummary summary = HomeSummary.empty();

  /// Number of archived chats carrying unread messages — drives the badge on
  /// the "Archived" row in the chat list.
  int get archivedUnreadCount =>
      archivedChats.where((c) => c.unreadCount > 0).length;

  int _tempIdCounter = 0;
  final Map<String, Uint8List> _localMediaCache = {};

  final Map<String, Uint8List> _localThumbnailCache = {};

  final Map<String, String> _translatedTextCache = {};
  final Set<String> _translatingMessageIds = {};

  // Pagination state for loading older history, keyed by chatId. A chat is
  // assumed to have more history until a page comes back short.
  final Map<String, bool> _hasMoreMessages = {};
  final Map<String, bool> _isLoadingMoreMessages = {};

  static const int _pageSize = 50;

  static const _outboxKey = 'pending_message_outbox';
  List<Map<String, dynamic>> _outbox = [];
  bool _outboxLoaded = false;
  bool _flushing = false;

  Future<void> _loadOutbox() async {
    if (_outboxLoaded) return;
    _outboxLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_outboxKey);
      if (raw == null || raw.isEmpty) return;
      _outbox = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('Could not read the outbox: $e');
    }
  }

  Future<void> _persistOutbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_outbox.isEmpty) {
        await prefs.remove(_outboxKey);
      } else {
        await prefs.setString(_outboxKey, jsonEncode(_outbox));
      }
    } catch (e) {
      debugPrint('Could not persist the outbox: $e');
    }
  }

  Future<void> _enqueue(Map<String, dynamic> send) async {
    await _loadOutbox();
    _outbox.add(send);
    await _persistOutbox();
  }

  Future<void> flushOutbox() async {
    if (_flushing) return;
    _flushing = true;
    try {
      await _loadOutbox();
      if (_outbox.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final send in _outbox) {
        if (!socketService.isConnected) {
          // Dropped mid-flush; keep this and everything after it in order.
          remaining.add(send);
          continue;
        }
        try {
          socketService.sendMessage(
            send['chatId'] as String,
            send['senderId'] as String,
            send['senderName'] as String? ?? '',
            send['content'] as String,
            send['tempId'] as String,
            replyToId: send['replyToId'] as String?,
            isDirect: send['isDirect'] as bool? ?? false,
            type: send['type'] as String? ?? 'text',
            mediaUrl: send['mediaUrl'] as String?,
            mediaMeta: send['mediaMeta'] == null
                ? null
                : Map<String, dynamic>.from(send['mediaMeta'] as Map),
          );
        } catch (e) {
          debugPrint('Outbox send failed, keeping it queued: $e');
          remaining.add(send);
        }
      }
      _outbox = remaining;
      await _persistOutbox();
    } finally {
      _flushing = false;
    }
  }

  Uint8List? getLocalMedia(String messageId) => _localMediaCache[messageId];
  Uint8List? getLocalThumbnail(String messageId) =>
      _localThumbnailCache[messageId];

  String? getTranslation(String messageId) => _translatedTextCache[messageId];
  bool isTranslating(String messageId) =>
      _translatingMessageIds.contains(messageId);

  Future<void> translateMessage(
    ChatMessageModel message, {
    required AppLanguage target,
  }) async {
    _translatingMessageIds.add(message.id);
    notifyListeners();
    try {
      final result = await TranslationService.instance.translate(
        text: message.content,
        target: target,
      );
      _translatedTextCache[message.id] = result;
    } finally {
      _translatingMessageIds.remove(message.id);
      notifyListeners();
    }
  }

  void clearTranslation(String messageId) {
    if (_translatedTextCache.remove(messageId) != null) notifyListeners();
  }

  bool hasMoreMessages(String chatId) => _hasMoreMessages[chatId] ?? true;
  bool isLoadingMoreMessages(String chatId) =>
      _isLoadingMoreMessages[chatId] ?? false;

  void Function(
    String chatId,
    String messageId,
    bool isPinned,
    DateTime? pinnedAt,
    ChatMessageModel? message,
  )?
  onMessagePinned;

  ChatProvider({
    required this.chatService,
    required this.socketService,
    required this.user,
  }) {
    if (user != null) {
      _init();
    }
  }

  void updateUser(UserModel? newUser) {
    if (user?.id != newUser?.id) {
      user = newUser;
      if (newUser != null) {
        _init();
      } else {
        _clearSocketCallbacks();
        recentChats = [];
        archivedChats = [];
        messages = {};
        notifyListeners();
        unawaited(DatabaseHelper.instance.wipeAll());
        ChatMessageModel.clearSenderCache();
        MediaVisibilityStore.instance.reset();
        _gallerySavedMessageIds.clear();
      }
    }
  }

  void _init() {
    socketService.onConnected = flushOutbox;
    socketService.onMessageReceived = _handleIncomingMessage;
    socketService.onMessageSent = _handleMessageSent;
    socketService.onUserTyping = _handleUserTyping;
    socketService.onUserStopTyping = _handleUserStopTyping;
    socketService.onMessageStatusChanged = _handleMessageStatusChanged;
    socketService.onMessagesRead = _handleMessagesRead;
    socketService.onUserOnlineStatus = _handleUserOnlineStatus;
    socketService.onMessageDeleted = _handleMessageDeleted;
    socketService.onMessageEdited = _handleMessageEdited;
    socketService.onMessagePinned = _handleMessagePinned;
    socketService.onMessageReacted = _handleMessageReacted;
    socketService.onConversationDeleted = _handleConversationDeleted;
  }

  void _clearSocketCallbacks() {
    socketService.onConnected = null;
    socketService.onMessageReceived = null;
    socketService.onMessageSent = null;
    socketService.onUserTyping = null;
    socketService.onUserStopTyping = null;
    socketService.onMessageStatusChanged = null;
    socketService.onMessagesRead = null;
    socketService.onUserOnlineStatus = null;
    socketService.onMessageDeleted = null;
    socketService.onMessageEdited = null;
    socketService.onMessagePinned = null;
    socketService.onMessageReacted = null;
    socketService.onConversationDeleted = null;
  }

  Future<void> loadRecentChats({bool force = false}) async {
    if (!force && recentChats.isNotEmpty) return;

    if (recentChats.isEmpty) {
      final cached = await _offlineStore.getCachedChats(archived: false);
      if (cached.isNotEmpty) {
        recentChats = cached;
        _deduplicateAndSortRecentChats();
        notifyListeners();
      }
    }

    // Only block on a spinner when there's truly nothing to show yet.
    isLoadingChats = recentChats.isEmpty;
    notifyListeners();
    try {
      final chats = await chatService.getConversations();
      recentChats = await _decryptChatPreviews(
        chats
            .map((e) => RecentChat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      _syncMutedChatsCache();
      unawaited(_offlineStore.saveChats(recentChats, archived: false));

      isLoadingChats = false;
      notifyListeners();
    } catch (e) {
      isLoadingChats = false;
      notifyListeners();
      debugPrint('Error loading recent chats: $e');
    }
  }

  /// Loads the archived chat list. Kept separate from [recentChats], which the
  /// server already excludes archived conversations from.
  Future<void> loadArchivedChats({bool force = false}) async {
    if (!force && archivedChats.isNotEmpty) return;

    if (archivedChats.isEmpty) {
      final cached = await _offlineStore.getCachedChats(archived: true);
      if (cached.isNotEmpty) {
        archivedChats = cached;
        notifyListeners();
      }
    }

    isLoadingArchivedChats = archivedChats.isEmpty;
    notifyListeners();
    try {
      final chats = await chatService.getConversations(archivedOnly: true);
      archivedChats = await _decryptChatPreviews(
        chats
            .map((e) => RecentChat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      _syncMutedChatsCache();
      unawaited(_offlineStore.saveChats(archivedChats, archived: true));
    } catch (e) {
      debugPrint('Error loading archived chats: $e');
    } finally {
      isLoadingArchivedChats = false;
      notifyListeners();
    }
  }

  static List<ChatMessageModel> _mergeNewer(
    List<ChatMessageModel> existing,
    List<ChatMessageModel> newer,
  ) {
    if (newer.isEmpty) return existing;
    final byId = <String, ChatMessageModel>{for (final m in existing) m.id: m};
    for (final m in newer) {
      byId[m.id] = m;
    }
    return byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> getMessages(String chatId) async {
    activeChatId = chatId;
    _clearUnreadCount(chatId);
    if (messages.containsKey(chatId)) return;

    _loadingMessageChats.add(chatId);
    notifyListeners();

    // Cached history renders instantly while the network call (below) fills
    // in anything sent since this device was last online.
    final myId = user?.id ?? '';
    final cached = myId.isEmpty
        ? <ChatMessageModel>[]
        : await _offlineStore.getMessages(chatId, myId, limit: _pageSize);
    if (cached.isNotEmpty) {
      messages = Map<String, List<ChatMessageModel>>.from(messages);
      messages[chatId] = cached;
      _hasMoreMessages[chatId] = cached.length >= _pageSize;
      _loadingMessageChats.remove(chatId);
    }
    notifyListeners();
    try {
      final anchor = cached.isEmpty ? null : cached.last.id;
      final encryptedHistory = await chatService.getMessages(
        chatId,
        limit: _pageSize,
        after: anchor,
      );
      final history = await _encryption.decryptAll(encryptedHistory);

      messages = Map<String, List<ChatMessageModel>>.from(messages);
      messages[chatId] = anchor == null
          ? history
          : _mergeNewer(cached, history);
      if (anchor == null) {
        _hasMoreMessages[chatId] = history.length >= _pageSize;
      }

      _loadingMessageChats.remove(chatId);
      notifyListeners();
      if (myId.isNotEmpty) unawaited(_offlineStore.saveAll(history, myId));
    } catch (e) {
      _loadingMessageChats.remove(chatId);
      notifyListeners();
      debugPrint('Error entering chat $chatId: $e');
    }
  }

  void _clearUnreadCount(String chatId) {
    final idx = recentChats.indexWhere(
      (c) => c.conversationId == chatId && c.unreadCount != 0,
    );
    if (idx != -1) {
      recentChats = List<RecentChat>.from(recentChats);
      recentChats[idx] = recentChats[idx].copyWith(unreadCount: 0);
      notifyListeners();
      return;
    }

    // Opening an archived chat must clear its badge too, or the "Archived"
    // row keeps counting it as unread.
    final archivedIdx = archivedChats.indexWhere(
      (c) => c.conversationId == chatId && c.unreadCount != 0,
    );
    if (archivedIdx == -1) return;
    archivedChats = List<RecentChat>.from(archivedChats);
    archivedChats[archivedIdx] = archivedChats[archivedIdx].copyWith(
      unreadCount: 0,
    );
    notifyListeners();
  }

  Future<void> loadMoreMessages(String chatId) async {
    if (_isLoadingMoreMessages[chatId] == true) return;
    if (_hasMoreMessages[chatId] == false) return;
    final existing = messages[chatId];
    if (existing == null || existing.isEmpty) return;

    _isLoadingMoreMessages[chatId] = true;
    notifyListeners();
    try {
      final encryptedOlder = await chatService.getMessages(
        chatId,
        limit: _pageSize,
        before: existing.first.createdAt,
      );
      final older = await _encryption.decryptAll(encryptedOlder);

      messages = Map<String, List<ChatMessageModel>>.from(messages);
      messages[chatId] = [...older, ...existing];
      _hasMoreMessages[chatId] = older.length >= _pageSize;

      final myId = user?.id;
      if (myId != null) unawaited(_offlineStore.saveAll(older, myId));
    } catch (e) {
      debugPrint('Error loading more messages for $chatId: $e');
    } finally {
      _isLoadingMoreMessages[chatId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? media,
    String? replyToId,
    bool isDirect = false,
    Uint8List? fileBytes,
    Uint8List? thumbnailBytes,
  }) async {
    final tempId =
        'temp_${DateTime.now().millisecondsSinceEpoch}_${_tempIdCounter++}';
    if (fileBytes != null) {
      _localMediaCache[tempId] = fileBytes;
    }
    if (thumbnailBytes != null) {
      _localThumbnailCache[tempId] = thumbnailBytes;
    }

    // Optimistic message shown immediately while socket delivers
    final optimisticMsg = ChatMessageModel(
      id: tempId,
      chatId: chatId,
      senderId: user?.id ?? '',
      senderName: user?.name ?? '',
      messageType: ChatMessageModel.messageTypeFromString(messageType),
      content: content,
      media: media != null
          ? MessageMedia(
              url: media['url'] ?? '',
              thumbnail: media['thumbnail'] ?? '',
              fileName: media['fileName'] ?? '',
              mimeType: media['mimeType'] ?? '',
              size: media['size'] ?? 0,
              duration: media['duration'] ?? 0,
            )
          : const MessageMedia(),
      mentions: const [],
      replyTo: replyToId,
      forwarded: false,
      edited: false,
      status: MessageStatus.sending,
      isPinned: false,
      deletedForEveryone: false,
      deletedForMe: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    messages = Map<String, List<ChatMessageModel>>.from(messages);
    final chatMsgs = List<ChatMessageModel>.from(messages[chatId] ?? []);
    chatMsgs.add(optimisticMsg);
    messages[chatId] = chatMsgs;
    notifyListeners();

    // The backend only ever sees this — the optimistic message above (shown
    // locally to the sender) stays plaintext.
    final senderId = user?.id ?? '';
    final encryptedContent = await _encryption.encryptContent(
      content,
      senderId: senderId,
      chatId: chatId,
    );

    if (fileBytes != null) {
      // Trigger background upload and then socket emission
      _uploadAndSendMedia(
        chatId: chatId,
        content: encryptedContent,
        messageType: messageType,
        mediaMeta: media ?? {},
        replyToId: replyToId,
        isDirect: isDirect,
        tempId: tempId,
        fileBytes: fileBytes,
        thumbnailBytes: thumbnailBytes,
      );
    } else {
      final send = <String, dynamic>{
        'chatId': chatId,
        'senderId': senderId,
        'senderName': user?.name ?? '',
        'content': encryptedContent,
        'tempId': tempId,
        'replyToId': replyToId,
        'isDirect': isDirect,
        'type': messageType,
        'mediaUrl': media != null ? media['url'] : null,
        'mediaMeta': media,
      };

      if (socketService.isConnected) {
        socketService.sendMessage(
          chatId,
          senderId,
          user?.name ?? '',
          encryptedContent,
          tempId,
          replyToId: replyToId,
          isDirect: isDirect,
          type: messageType,
          mediaUrl: media != null ? media['url'] : null,
          mediaMeta: media,
        );
      } else {
        await _enqueue(send);
      }
    }
  }

  /// [content] arrives already encrypted — the caller ([sendMessage]) does
  /// it once up front since both this and the non-upload path need it.
  Future<void> _uploadAndSendMedia({
    required String chatId,
    required String content,
    required String messageType,
    required Map<String, dynamic> mediaMeta,
    required String? replyToId,
    required bool isDirect,
    required String tempId,
    required Uint8List fileBytes,
    Uint8List? thumbnailBytes,
  }) async {
    try {
      final fileName = mediaMeta['fileName'] ?? 'file';
      final mimeType = mediaMeta['mimeType'] ?? 'application/octet-stream';

      // Uploaded in parallel — the thumbnail is a small independent image,
      // no reason to wait on the (often much larger) video upload first.
      final results = await Future.wait([
        chatService.uploadFileToCloud(fileBytes, fileName, mimeType),
        if (thumbnailBytes != null)
          chatService.uploadFileToCloud(
            thumbnailBytes,
            FileNamingService.getUploadName(
              'thumb_$fileName.jpg',
              'image/jpeg',
            ),
            'image/jpeg',
          ),
      ]);
      final mediaUrl = results[0];
      final thumbnailUrl = thumbnailBytes != null ? results[1] : null;

      final updatedMediaMeta = Map<String, dynamic>.from(mediaMeta);
      updatedMediaMeta['url'] = mediaUrl;
      if (thumbnailUrl != null) updatedMediaMeta['thumbnail'] = thumbnailUrl;

      // Update the optimistic message's media url locally
      messages = Map<String, List<ChatMessageModel>>.from(messages);
      final chatMsgs = List<ChatMessageModel>.from(messages[chatId] ?? []);
      final idx = chatMsgs.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        chatMsgs[idx] = chatMsgs[idx].copyWith(
          media: MessageMedia(
            url: mediaUrl,
            thumbnail: updatedMediaMeta['thumbnail'] ?? '',
            fileName: fileName,
            mimeType: mimeType,
            size: updatedMediaMeta['size'] ?? 0,
            duration: updatedMediaMeta['duration'] ?? 0,
          ),
        );
        messages[chatId] = chatMsgs;
        notifyListeners();
      }

      socketService.sendMessage(
        chatId,
        user?.id ?? '',
        user?.name ?? '',
        content,
        tempId,
        replyToId: replyToId,
        isDirect: isDirect,
        type: messageType,
        mediaUrl: mediaUrl,
        mediaMeta: updatedMediaMeta,
      );
    } catch (e) {
      debugPrint('Failed background upload: $e');
      // Mark local message as failed
      messages = Map<String, List<ChatMessageModel>>.from(messages);
      final chatMsgs = List<ChatMessageModel>.from(messages[chatId] ?? []);
      final idx = chatMsgs.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        chatMsgs[idx] = chatMsgs[idx].copyWith(status: MessageStatus.failed);
        messages[chatId] = chatMsgs;
        notifyListeners();
      }
    }
  }

  void _sortRecentChats(List<RecentChat> chats) {
    _deduplicateAndSortRecentChats();
  }

  Future<List<RecentChat>> _decryptChatPreviews(List<RecentChat> chats) async {
    return Future.wait(
      chats.map((c) async {
        final lastMessage = c.lastMessage;
        if (lastMessage == null) return c;
        return c.copyWith(lastMessage: await _encryption.decrypt(lastMessage));
      }),
    );
  }

  void _deduplicateAndSortRecentChats() {
    final Map<String, RecentChat> uniqueMap = {};
    for (final chat in recentChats) {
      final key = chat.conversationId.isNotEmpty
          ? chat.conversationId
          : (chat.id.isNotEmpty ? chat.id : chat.name);

      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = chat;
      } else {
        final existing = uniqueMap[key]!;
        final existingTime =
            existing.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final newTime =
            chat.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (newTime.isAfter(existingTime)) {
          uniqueMap[key] = chat.copyWith(
            unreadCount: existing.unreadCount > chat.unreadCount
                ? existing.unreadCount
                : chat.unreadCount,
          );
        }
      }
    }
    final list = uniqueMap.values.toList();
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    recentChats = list;
  }

  // ─── Socket event handlers ────────────────────────────────────────────────

  /// Replaces the optimistic (temp) message with the confirmed server message.
  Future<void> _handleMessageSent(
    ChatMessageModel encryptedMessage,
    String clientMessageId,
  ) async {
    final chatId = encryptedMessage.chatId;
    if (chatId.isEmpty) return;

    final message = await _encryption.decrypt(encryptedMessage);

    messages = Map<String, List<ChatMessageModel>>.from(messages);
    final chatMsgs = List<ChatMessageModel>.from(messages[chatId] ?? []);

    // Replace by clientMessageId (temp ID) first, fall back to real ID
    final idx = chatMsgs.indexWhere(
      (m) => m.id == clientMessageId || m.id == message.id,
    );
    if (idx != -1) {
      chatMsgs[idx] = message;
    } else {
      chatMsgs.add(message);
    }
    messages[chatId] = chatMsgs;

    final myId = user?.id;
    if (myId != null) unawaited(_offlineStore.upsert(message, myId));

    // Clean up local media bytes cache upon server confirmation
    _localMediaCache.remove(clientMessageId);
    _localThumbnailCache.remove(clientMessageId);

    // Update last message in recent chats
    var chatExists = false;
    final updatedRecentChats = recentChats.map((c) {
      if (c.conversationId == chatId) {
        chatExists = true;
        return c.copyWith(
          lastMessageContent: message.content,
          lastMessageAt: message.createdAt,
          lastMessageSenderId: message.senderId,
        );
      }
      return c;
    }).toList();

    // The chat is absent from the list when it's brand new, or when the user
    // previously deleted it — sending into it must bring it back.
    if (!chatExists) {
      loadRecentChats(force: true);
      return;
    }

    recentChats = updatedRecentChats;
    _sortRecentChats(recentChats);

    notifyListeners();
  }

  bool _applyToArchivedChat(String chatId, ChatMessageModel message) {
    final index = archivedChats.indexWhere((c) => c.conversationId == chatId);
    if (index == -1) return false;

    final isMsgFromMe = message.senderId == user?.id;
    final updated = List<RecentChat>.from(archivedChats);
    updated[index] = updated[index].copyWith(
      lastMessageContent: message.content,
      lastMessageAt: message.createdAt,
      lastMessageSenderId: message.senderId,
      unreadCount: (activeChatId == chatId || isMsgFromMe)
          ? 0
          : updated[index].unreadCount + 1,
    );
    archivedChats = updated;
    return true;
  }

  Future<void> _handleIncomingMessage(
    ChatMessageModel encryptedMessage,
    String? clientMessageId,
  ) async {
    final chatId = encryptedMessage.chatId;
    if (chatId.isEmpty) return;

    if (BlockedUsersStore.isBlocked(encryptedMessage.senderId)) {
      debugPrint(
        '[Chat] Dropped message from blocked user ${encryptedMessage.senderId}',
      );
      return;
    }

    final message = await _encryption.decrypt(encryptedMessage);

    messages = Map<String, List<ChatMessageModel>>.from(messages);
    final chatMsgs = List<ChatMessageModel>.from(messages[chatId] ?? []);

    final existingIndex = chatMsgs.indexWhere(
      (m) =>
          m.id == message.id ||
          (clientMessageId != null && m.id == clientMessageId),
    );
    if (existingIndex != -1) {
      chatMsgs[existingIndex] = message;
      // Clean up local media bytes cache if any
      if (clientMessageId != null) {
        _localMediaCache.remove(clientMessageId);
        _localThumbnailCache.remove(clientMessageId);
      }
    } else {
      chatMsgs.add(message);
      if (message.senderId != user?.id) {
        unawaited(_maybeSaveToGallery(message));
      }
    }
    messages[chatId] = chatMsgs;

    final myId = user?.id;
    if (myId != null) unawaited(_offlineStore.upsert(message, myId));

    var chatExists = false;
    final updatedRecentChats = recentChats.map((c) {
      if (c.conversationId == chatId) {
        chatExists = true;
        final isMsgFromMe = message.senderId == user?.id;
        return c.copyWith(
          lastMessageContent: message.content,
          lastMessageAt: message.createdAt,
          lastMessageSenderId: message.senderId,
          unreadCount: (activeChatId == chatId || isMsgFromMe)
              ? 0
              : c.unreadCount + 1,
        );
      }
      return c;
    }).toList();

    if (chatExists) {
      recentChats = updatedRecentChats;
      _sortRecentChats(recentChats);
      notifyListeners();
    } else if (_applyToArchivedChat(chatId, message)) {
      // Archived chats stay archived when new messages land — they just
      // update in place, matching WhatsApp's "keep chats archived" default.
      notifyListeners();
    } else {
      loadRecentChats(force: true);
    }

    // If the message arrived in the active chat from the peer, send a read receipt
    if (activeChatId == chatId && message.senderId != user?.id) {
      socketService.markMessagesRead(chatId, user?.id ?? '', message.senderId);
    }
  }

  // ── Gallery auto-save ──────────────────────────────────────────────────────

  static const Set<MessageType> _gallerySavableTypes = {
    MessageType.image,
    MessageType.video,
    MessageType.gif,
  };

  final Set<String> _gallerySavedMessageIds = {};

  Future<void> _maybeSaveToGallery(ChatMessageModel message) async {
    if (!_gallerySavableTypes.contains(message.messageType)) return;

    final url = message.media.url;
    if (url.isEmpty) return;

    // Policy check before any download or file work — a chat set to Never
    // shouldn't even cost bytes.
    if (!MediaVisibilityStore.instance.shouldSaveFor(message.chatId)) return;

    if (!await DataUsageStore.instance.canAutoDownloadNow()) return;

    if (message.id.isEmpty || !_gallerySavedMessageIds.add(message.id)) return;

    File? staged;
    try {
      final isVideo = message.messageType == MessageType.video;

      final cached = await MediaCacheService().getCachedFile(
        url,
        fileName: isVideo ? _videoCacheKey(message.media) : null,
      );

      staged = await _stageForGallery(cached, message);
      await GallerySaveService.instance.save(
        path: staged.path,
        isVideo: isVideo,
      );
    } catch (e) {
      // Retryable next session — drop the id so a later redelivery can try.
      _gallerySavedMessageIds.remove(message.id);
      debugPrint('Gallery auto-save failed for ${message.id}: $e');
    } finally {
      // The gallery holds its own copy now; this one was only a vehicle.
      try {
        await staged?.delete();
      } catch (_) {}
    }
  }

  String _videoCacheKey(MessageMedia media) => media.fileName.isNotEmpty
      ? media.fileName
      : 'video_${media.url.hashCode}.mp4';

  /// Copies [source] to the temp directory under a name whose extension
  /// matches what the bytes actually are.
  Future<File> _stageForGallery(File source, ChatMessageModel message) async {
    var mime = message.media.mimeType;
    if (mime.isEmpty) {
      mime = message.messageType == MessageType.video
          ? 'video/mp4'
          : (message.messageType == MessageType.gif
                ? 'image/gif'
                : 'image/jpeg');
    }

    final ext = p.extension(
      FileNamingService.getUploadName(message.media.fileName, mime),
    );
    final at = message.createdAt.toLocal();
    final stamp =
        '${at.year}${_pad2(at.month)}${_pad2(at.day)}'
        '_${_pad2(at.hour)}${_pad2(at.minute)}${_pad2(at.second)}';
    // Message-id tail disambiguates two messages landing in the same second.
    final tail = message.id.length <= 6
        ? message.id
        : message.id.substring(message.id.length - 6);

    final dir = await getTemporaryDirectory();
    return source.copy(
      p.join(
        dir.path,
        'Talkmos_$stamp'
        '_$tail$ext',
      ),
    );
  }

  static String _pad2(int v) => v.toString().padLeft(2, '0');

  void _handleUserTyping(String chatId, String userId) {
    if (userId == user?.id) return;
    typingUsers = Map<String, Set<String>>.from(typingUsers);
    final users = Set<String>.from(typingUsers[chatId] ?? {});
    users.add(userId);
    typingUsers[chatId] = users;
    notifyListeners();
  }

  void _handleUserStopTyping(String chatId, String userId) {
    if (userId == user?.id) return;
    typingUsers = Map<String, Set<String>>.from(typingUsers);
    final users = Set<String>.from(typingUsers[chatId] ?? {});
    users.remove(userId);
    typingUsers[chatId] = users;
    notifyListeners();
  }

  void _handleMessageStatusChanged(String messageId, MessageStatus status) {
    for (final entry in messages.entries) {
      final source = entry.value;
      final index = source.indexWhere((m) => m.id == messageId);
      if (index == -1) continue;

      if (status.index <= source[index].status.index) return;

      final chatMsgs = List<ChatMessageModel>.from(source);
      chatMsgs[index] = chatMsgs[index].copyWith(status: status);
      messages = Map<String, List<ChatMessageModel>>.from(messages)
        ..[entry.key] = chatMsgs;
      notifyListeners();
      unawaited(_offlineStore.updateStatus(messageId, status));
      return;
    }
  }

  void _handleMessagesRead(String readerId, [String? chatId]) {
    final myId = user?.id;

    if (readerId == myId) return;

    final targets = chatId != null
        ? (messages.containsKey(chatId) ? <String>[chatId] : const <String>[])
        : messages.keys.toList();
    if (targets.isEmpty) return;

    Map<String, List<ChatMessageModel>>? updated;

    for (final key in targets) {
      final source = messages[key];
      if (source == null) continue;

      List<ChatMessageModel>? chatMsgs;
      for (int i = 0; i < source.length; i++) {
        final msg = source[i];
        // Mark our sent messages as read when the peer reads them
        if (msg.senderId == myId && msg.status != MessageStatus.read) {
          // Copy lazily — only once this chat is known to change.
          chatMsgs ??= List<ChatMessageModel>.from(source);
          chatMsgs[i] = msg.copyWith(status: MessageStatus.read);
        }
      }
      if (chatMsgs != null) {
        updated ??= Map<String, List<ChatMessageModel>>.from(messages);
        updated[key] = chatMsgs;
      }
    }

    // Nothing actually changed — return without notifying, so a duplicate
    // receipt does not rebuild every listening widget for no reason.
    if (updated == null) return;
    messages = updated;
    notifyListeners();
  }

  // Exposed so screens can subscribe (e.g. ChatScreen for online dot)
  void Function(String userId, bool online, DateTime? lastSeenAt)?
  onUserOnlineStatus;

  void _handleUserOnlineStatus(
    String userId,
    bool online,
    DateTime? lastSeenAt,
  ) {
    onUserOnlineStatus?.call(userId, online, lastSeenAt);
  }

  void _handleMessageDeleted(
    String chatId,
    String messageId,
    bool forEveryone,
  ) {
    final list = messages[chatId];
    if (list != null) {
      final index = list.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updatedList = List<ChatMessageModel>.from(list);
        if (forEveryone) {
          updatedList[index] = updatedList[index].copyWith(
            content: 'This message was deleted',
            deletedForEveryone: true,
          );
          unawaited(_offlineStore.markDeletedForEveryone(messageId));
        } else {
          updatedList.removeAt(index);
          unawaited(_offlineStore.delete(messageId));
        }
        messages = Map<String, List<ChatMessageModel>>.from(messages);
        messages[chatId] = updatedList;
        notifyListeners();
      }
    }
  }

  /// The actual state mutation, shared by the optimistic local edit and the
  /// server-confirmed one — expects [plainContent] already decrypted.
  void _applyEditedContent(
    String chatId,
    String messageId,
    String plainContent,
    DateTime? editedAt,
  ) {
    final list = messages[chatId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final updatedList = List<ChatMessageModel>.from(list);
    updatedList[index] = updatedList[index].copyWith(
      content: plainContent,
      edited: true,
      editedAt: editedAt ?? DateTime.now(),
    );
    final myId = user?.id;
    if (myId != null) {
      unawaited(_offlineStore.upsert(updatedList[index], myId));
    }
    messages = Map<String, List<ChatMessageModel>>.from(messages);
    messages[chatId] = updatedList;
    notifyListeners();
  }

  Future<void> _handleMessageEdited(
    String chatId,
    String messageId,
    String encryptedContent,
    DateTime? editedAt,
  ) async {
    final existing = messages[chatId]
        ?.where((m) => m.id == messageId)
        .firstOrNull;
    final senderId = existing?.senderId;
    if (senderId == null || senderId.isEmpty) return;

    final plainContent = await _encryption.decryptContent(
      encryptedContent,
      senderId: senderId,
      chatId: chatId,
    );
    _applyEditedContent(chatId, messageId, plainContent, editedAt);
  }

  Future<void> editMessage(
    String chatId,
    String messageId,
    String content,
  ) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    _applyEditedContent(chatId, messageId, trimmed, DateTime.now());

    final senderId = user?.id ?? '';
    final encrypted = await _encryption.encryptContent(
      trimmed,
      senderId: senderId,
      chatId: chatId,
    );
    socketService.editMessage(chatId, messageId, encrypted);
  }

  void _handleMessagePinned(
    String chatId,
    String messageId,
    bool isPinned,
    DateTime? pinnedAt,
    ChatMessageModel? message,
  ) {
    final list = messages[chatId];
    if (list != null) {
      final index = list.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updatedList = List<ChatMessageModel>.from(list);
        updatedList[index] = updatedList[index].copyWith(
          isPinned: isPinned,
          pinnedAt: pinnedAt,
        );
        messages = Map<String, List<ChatMessageModel>>.from(messages);
        messages[chatId] = updatedList;
      }
    }
    notifyListeners();
    if (onMessagePinned != null) {
      onMessagePinned!(chatId, messageId, isPinned, pinnedAt, message);
    }
  }

  // ─── Reactions ────────────────────────────────────────────────────────────

  Future<void> reactToMessage(
    String chatId,
    String messageId,
    String emoji,
  ) async {
    final myId = user?.id ?? '';
    if (myId.isEmpty) return;

    final previous = _myReactionEmoji(chatId, messageId, myId);
    // Tapping the same emoji again removes it.
    final next = (previous == emoji) ? '' : emoji;

    _applyReaction(chatId, messageId, myId, next);
    notifyListeners();

    try {
      await chatService.reactToMessage(messageId, next);
    } catch (e) {
      debugPrint('[ChatProvider] reactToMessage failed: $e');
      // Roll back to the previous reaction on failure.
      _applyReaction(chatId, messageId, myId, previous ?? '');
      notifyListeners();
    }
  }

  void _handleMessageReacted(
    String chatId,
    String messageId,
    String userId,
    String? emoji,
  ) {
    _applyReaction(chatId, messageId, userId, emoji ?? '');
    notifyListeners();
  }

  /// Sets [userId]'s reaction on a message to [emoji] (empty removes it),
  /// enforcing one reaction per user.
  void _applyReaction(
    String chatId,
    String messageId,
    String userId,
    String emoji,
  ) {
    final list = messages[chatId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final reactions = List<dynamic>.from(list[index].reactions)
      ..removeWhere((r) => _reactionUserId(r) == userId);
    if (emoji.isNotEmpty) {
      reactions.add({'userId': userId, 'emoji': emoji});
    }

    final updatedList = List<ChatMessageModel>.from(list);
    updatedList[index] = updatedList[index].copyWith(reactions: reactions);
    messages = Map<String, List<ChatMessageModel>>.from(messages);
    messages[chatId] = updatedList;
  }

  /// The emoji [userId] has currently reacted with on [messageId], or null.
  String? _myReactionEmoji(String chatId, String messageId, String userId) {
    final list = messages[chatId];
    if (list == null) return null;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index == -1) return null;
    for (final r in list[index].reactions) {
      if (_reactionUserId(r) == userId && r is Map) {
        return r['emoji']?.toString();
      }
    }
    return null;
  }

  /// Extracts the reacting user's id from a reaction entry, whose `userId`
  /// may be a plain id string or a populated `{_id, name}` object.
  String _reactionUserId(dynamic r) {
    if (r is! Map) return '';
    final u = r['userId'];
    if (u is Map) return u['_id']?.toString() ?? '';
    return u?.toString() ?? '';
  }

  Future<void> togglePinChat(RecentChat chat) async {
    final newPinnedStatus = !chat.isPinned;
    // Optimistically update
    recentChats = recentChats.map((c) {
      if (c.conversationId == chat.conversationId) {
        return c.copyWith(isPinned: newPinnedStatus);
      }
      return c;
    }).toList();
    _sortRecentChats(recentChats);
    notifyListeners();

    try {
      await chatService.setConversationPreferences(
        chat.conversationId,
        isPinned: newPinnedStatus,
      );
    } catch (e) {
      debugPrint('Error toggling pin status: $e');
      loadRecentChats(); // revert by reloading
    }
  }

  Future<void> toggleMuteChat(RecentChat chat) async {
    final newMuteStatus = !chat.isMuted;
    // Optimistically update
    recentChats = recentChats.map((c) {
      if (c.conversationId == chat.conversationId) {
        return c.copyWith(isMuted: newMuteStatus);
      }
      return c;
    }).toList();
    archivedChats = archivedChats.map((c) {
      if (c.conversationId == chat.conversationId) {
        return c.copyWith(isMuted: newMuteStatus);
      }
      return c;
    }).toList();
    _syncMutedChatsCache();
    notifyListeners();

    try {
      await chatService.setConversationPreferences(
        chat.conversationId,
        isMuted: newMuteStatus,
      );
    } catch (e) {
      debugPrint('Error toggling mute status: $e');
      loadRecentChats(); // revert
    }
  }

  void _syncMutedChatsCache() {
    final muted = <String>{
      for (final c in recentChats)
        if (c.isMuted) c.conversationId,
      for (final c in archivedChats)
        if (c.isMuted) c.conversationId,
    };
    MutedChatsStore.sync(muted);
  }

  /// Archives or unarchives a chat, moving it between [recentChats] and
  /// [archivedChats] so both lists stay correct without a round trip.
  Future<void> toggleArchiveChat(RecentChat chat) async {
    final newArchivedStatus = !chat.isArchived;
    final chatId = chat.conversationId;
    final previousRecent = recentChats;
    final previousArchived = archivedChats;

    final moved = chat.copyWith(isArchived: newArchivedStatus);
    if (newArchivedStatus) {
      recentChats = recentChats
          .where((c) => c.conversationId != chatId)
          .toList();
      archivedChats = [
        moved,
        ...archivedChats.where((c) => c.conversationId != chatId),
      ];
    } else {
      archivedChats = archivedChats
          .where((c) => c.conversationId != chatId)
          .toList();
      recentChats = [
        moved,
        ...recentChats.where((c) => c.conversationId != chatId),
      ];
      _sortRecentChats(recentChats);
    }
    notifyListeners();

    try {
      await chatService.setConversationPreferences(
        chatId,
        isArchived: newArchivedStatus,
      );
    } catch (e) {
      debugPrint('Error toggling archive status: $e');
      recentChats = previousRecent;
      archivedChats = previousArchived;
      notifyListeners();
    }
  }

  Future<void> deleteChat(RecentChat chat) async {
    final previousRecent = recentChats;
    final previousArchived = archivedChats;
    final chatId = chat.conversationId;
    // Drop from whichever list holds it — delete is reachable from both the
    // main chat list and the archived one.
    recentChats = recentChats.where((c) => c.conversationId != chatId).toList();
    archivedChats = archivedChats
        .where((c) => c.conversationId != chatId)
        .toList();

    messages = Map<String, List<ChatMessageModel>>.from(messages)
      ..remove(chatId);
    _hasMoreMessages.remove(chatId);
    _isLoadingMoreMessages.remove(chatId);
    unawaited(_offlineStore.deleteMessagesForChat(chatId));
    unawaited(_offlineStore.removeCachedChat(chatId));
    notifyListeners();

    try {
      await chatService.setConversationPreferences(chatId, hidden: true);
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      recentChats = previousRecent;
      archivedChats = previousArchived;
      notifyListeners();
    }
  }

  /// Leaves a group chat and removes it from the current user's list.
  Future<void> leaveGroupChat(RecentChat chat) async {
    final previousRecent = recentChats;
    final previousArchived = archivedChats;
    final chatId = chat.conversationId;
    recentChats = recentChats.where((c) => c.conversationId != chatId).toList();
    archivedChats = archivedChats
        .where((c) => c.conversationId != chatId)
        .toList();
    notifyListeners();

    try {
      await chatService.leaveConversation(chatId);
    } catch (e) {
      debugPrint('Error leaving group: $e');
      recentChats = previousRecent;
      archivedChats = previousArchived;
      notifyListeners();
      rethrow;
    }
  }

  String? deletedChatId;

  /// Socket: a group this account was in has been deleted for everyone.
  void _handleConversationDeleted(String chatId, String deletedBy) {
    final hadIt =
        recentChats.any((c) => c.conversationId == chatId) ||
        archivedChats.any((c) => c.conversationId == chatId);

    recentChats = recentChats.where((c) => c.conversationId != chatId).toList();
    archivedChats = archivedChats
        .where((c) => c.conversationId != chatId)
        .toList();
    messages = Map<String, List<ChatMessageModel>>.from(messages)
      ..remove(chatId);
    _hasMoreMessages.remove(chatId);
    _isLoadingMoreMessages.remove(chatId);
    unawaited(_offlineStore.deleteMessagesForChat(chatId));
    unawaited(_offlineStore.removeCachedChat(chatId));

    // Only worth a screen-closing signal if this device is actually in it.
    deletedChatId = activeChatId == chatId ? chatId : null;
    if (hadIt || deletedChatId != null) notifyListeners();
    deletedChatId = null;
  }

  /// Deletes a group for everyone. Owner only — the server rejects anyone
  /// else, and the list is put back if it does.
  Future<void> deleteGroupChat(RecentChat chat) async {
    final previousRecent = recentChats;
    final previousArchived = archivedChats;
    final chatId = chat.conversationId;
    recentChats = recentChats.where((c) => c.conversationId != chatId).toList();
    archivedChats = archivedChats
        .where((c) => c.conversationId != chatId)
        .toList();
    notifyListeners();

    try {
      await chatService.deleteConversation(chatId);
      // The history is unreachable once the group is gone; leaving it cached
      // would show it again if a chat with the same id were ever opened.
      messages = Map<String, List<ChatMessageModel>>.from(messages)
        ..remove(chatId);
      unawaited(_offlineStore.deleteMessagesForChat(chatId));
      unawaited(_offlineStore.removeCachedChat(chatId));
    } catch (e) {
      debugPrint('Error deleting group: $e');
      recentChats = previousRecent;
      archivedChats = previousArchived;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> togglePinMessage(
    String chatId,
    String messageId,
    bool isPinned,
  ) async {
    try {
      await chatService.togglePinMessage(messageId, isPinned);
      // The socket event will trigger the local update, but we can also optimistically update
      final list = messages[chatId];
      if (list != null) {
        final index = list.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final updatedList = List<ChatMessageModel>.from(list);
          updatedList[index] = updatedList[index].copyWith(
            isPinned: isPinned,
            pinnedAt: isPinned ? DateTime.now() : null,
          );
          messages = Map<String, List<ChatMessageModel>>.from(messages);
          messages[chatId] = updatedList;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error toggling pin message: $e');
    }
  }

  @override
  void dispose() {
    _clearSocketCallbacks();
    super.dispose();
  }
}
