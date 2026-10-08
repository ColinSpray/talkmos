import 'package:json_annotation/json_annotation.dart';
import 'converters/local_date_time_converter.dart';

part 'chat_message_model.g.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType {
  text,
  image,
  video,
  audio,
  voice,
  file,
  gif,
  sticker,
  location,
  contact,
  system,
}

@JsonSerializable()
class MessageMedia {
  @JsonKey(defaultValue: '')
  final String url;

  @JsonKey(defaultValue: '')
  final String thumbnail;

  @JsonKey(defaultValue: '')
  final String fileName;

  @JsonKey(defaultValue: '')
  final String mimeType;

  @JsonKey(defaultValue: 0)
  final int size;

  @JsonKey(defaultValue: 0)
  final int duration;

  const MessageMedia({
    this.url = '',
    this.thumbnail = '',
    this.fileName = '',
    this.mimeType = '',
    this.size = 0,
    this.duration = 0,
  });

  factory MessageMedia.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MessageMedia();
    return _$MessageMediaFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MessageMediaToJson(this);
}

@JsonSerializable()
class ChatMessageModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String chatId;

  @JsonKey(defaultValue: '')
  final String senderId;

  @JsonKey(defaultValue: '')
  final String senderName;

  @JsonKey(defaultValue: '')
  final String senderAvatarUrl;

  @JsonKey(defaultValue: '')
  final String receiverId;

  final MessageType messageType;

  @JsonKey(defaultValue: '')
  final String content;

  final MessageMedia media;

  @JsonKey(defaultValue: [])
  final List<String> mentions;
  final String? replyTo;

  @JsonKey(defaultValue: false)
  final bool forwarded;

  @JsonKey(defaultValue: false)
  final bool edited;

  @LocalDateTimeConverterNullable()
  final DateTime? editedAt;

  final MessageStatus status;

  @JsonKey(defaultValue: false)
  final bool isPinned;

  @LocalDateTimeConverterNullable()
  final DateTime? pinnedAt;

  @JsonKey(defaultValue: false)
  final bool deletedForEveryone;

  @JsonKey(defaultValue: [])
  final List<String> deletedForMe;

  @LocalDateTimeConverterNullable()
  final DateTime? deletedAt;

  final List<dynamic> reactions;

  @JsonKey(defaultValue: false)
  final bool isStarred;

  @JsonKey(name: 'clientMessageId')
  final String? tempId;

  @LocalDateTimeConverter()
  final DateTime createdAt;

  @LocalDateTimeConverter()
  final DateTime updatedAt;

  String get messageId => id;
  String get messageText => content;

  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl = '',
    this.receiverId = '',
    required this.messageType,
    required this.content,
    required this.media,
    required this.mentions,
    this.replyTo,
    required this.forwarded,
    required this.edited,
    this.editedAt,
    required this.status,
    required this.isPinned,
    this.pinnedAt,
    required this.deletedForEveryone,
    required this.deletedForMe,
    this.deletedAt,
    this.reactions = const [],
    this.isStarred = false,
    this.tempId,
    required this.createdAt,
    required this.updatedAt,
  });

  static final Map<String, String> _senderStrings = {};

  static String _intern(String value) =>
      value.isEmpty ? value : (_senderStrings[value] ??= value);

  /// Drops the interned sender strings. Called when the signed-in user changes,
  /// so one account's names and avatars are not held alive under the next.
  static void clearSenderCache() => _senderStrings.clear();

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['senderId'] ?? json['sender'];

    String sId = '';
    String sName = '';
    String sAvatar = '';
    if (sender is Map) {
      sId = _intern(
        sender['_id']?.toString() ?? sender['id']?.toString() ?? '',
      );
      sName = _intern(
        sender['name']?.toString() ?? sender['username']?.toString() ?? '',
      );
      sAvatar = _intern(
        sender['avatarUrl']?.toString() ??
            sender['profileImage']?.toString() ??
            '',
      );
    } else if (sender != null) {
      sId = _intern(sender.toString());
    }

    if (sName.isEmpty && json['senderName'] != null) {
      sName = _intern(json['senderName'].toString());
    }
    if (sName.isEmpty && json['name'] != null && sender is! Map) {
      sName = _intern(json['name'].toString());
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    if (!data.containsKey('_id') && data.containsKey('messageId')) {
      data['_id'] = data['messageId'];
    } else if (!data.containsKey('_id') && data.containsKey('id')) {
      data['_id'] = data['id'];
    }

    data['senderId'] = sId;
    data['senderName'] = sName;
    data['senderAvatarUrl'] = sAvatar;

    if (data['content'] == null && data['messageText'] != null) {
      data['content'] = data['messageText'];
    }

    data['media'] = data['media'] != null
        ? Map<String, dynamic>.from(data['media'] as Map)
        : <String, dynamic>{};

    final typeVal = data['messageType'] ?? data['type'];
    data['messageType'] = (typeVal is String)
        ? messageTypeFromString(typeVal).name
        : MessageType.text.name;

    data['status'] = (data['status'] is String)
        ? statusFromString(data['status'] as String).name
        : MessageStatus.sent.name;

    if (data['createdAt'] == null) {
      data['createdAt'] = DateTime.now().toIso8601String();
    }
    if (data['updatedAt'] == null) {
      data['updatedAt'] = DateTime.now().toIso8601String();
    }

    data['clientMessageId'] = data['clientMessageId'] ?? data['tempId'];

    return _$ChatMessageModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  ChatMessageModel copyWith({
    MessageStatus? status,
    String? content,
    bool? edited,
    DateTime? editedAt,
    String? receiverId,
    List<dynamic>? reactions,
    bool? isStarred,
    bool? deletedForEveryone,
    List<String>? deletedForMe,
    DateTime? deletedAt,
    bool? isPinned,
    DateTime? pinnedAt,
    MessageMedia? media,
    String? tempId,
  }) {
    return ChatMessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      receiverId: receiverId ?? this.receiverId,
      messageType: messageType,
      content: content ?? this.content,
      media: media ?? this.media,
      mentions: mentions,
      replyTo: replyTo,
      forwarded: forwarded,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      status: status ?? this.status,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: isPinned == false ? null : (pinnedAt ?? this.pinnedAt),
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      deletedForMe: deletedForMe ?? this.deletedForMe,
      deletedAt: deletedAt ?? this.deletedAt,
      reactions: reactions ?? this.reactions,
      isStarred: isStarred ?? this.isStarred,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tempId: tempId ?? this.tempId,
    );
  }

  static MessageStatus statusFromString(String? value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  static MessageType messageTypeFromString(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'voice':
        return MessageType.voice;
      case 'file':
        return MessageType.file;
      case 'gif':
        return MessageType.gif;
      case 'sticker':
        return MessageType.sticker;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}
