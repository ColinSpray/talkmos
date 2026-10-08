import 'package:json_annotation/json_annotation.dart';
import 'chat_message_model.dart';
import 'converters/local_date_time_converter.dart';

part 'recent_chat.g.dart';

@JsonSerializable()
class ChatMember {
  @JsonKey(name: '_id')
  final String id;

  final String name;

  @JsonKey(defaultValue: '')
  final String imageUrl;

  ChatMember({required this.id, required this.name, this.imageUrl = ''});

  factory ChatMember.fromJson(Map<String, dynamic> json) =>
      _$ChatMemberFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMemberToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RecentChat {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(defaultValue: 'direct')
  final String chatType;

  final String? spaceId;

  // Shape of an active call isn't known yet; keep it loose for now.
  final dynamic activeCall;

  @LocalDateTimeConverterNullable()
  final DateTime? deletedAt;

  @LocalDateTimeConverter()
  final DateTime createdAt;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String imageUrl;

  @JsonKey(defaultValue: <ChatMember>[])
  final List<ChatMember> members;

  @LocalDateTimeConverterNullable()
  final DateTime? lastActivityAt;

  // Not present in the sample payload, but keeping it since chats
  // will presumably carry a last message once one exists.
  final ChatMessageModel? lastMessage;

  @JsonKey(defaultValue: false)
  final bool isPinned;

  @JsonKey(defaultValue: false)
  final bool isMuted;

  @JsonKey(defaultValue: false)
  final bool isArchived;

  @JsonKey(defaultValue: 0)
  final int unreadCount;

  RecentChat({
    required this.id,
    required this.chatType,
    this.spaceId,
    this.activeCall,
    this.deletedAt,
    required this.createdAt,
    required this.name,
    required this.imageUrl,
    this.members = const [],
    this.lastActivityAt,
    this.lastMessage,
    required this.isPinned,
    required this.isMuted,
    required this.isArchived,
    required this.unreadCount,
  });

  String get conversationId => id;
  String get title => name;
  String? get avatarUrl => imageUrl.isEmpty ? null : imageUrl;
  String? get lastMessageContent => lastMessage?.content;
  DateTime? get lastMessageAt =>
      lastMessage?.createdAt ?? lastActivityAt ?? createdAt;
  String? get lastMessageSenderId => lastMessage?.senderId;

  ChatMember? peerFor(String? myId) {
    if (chatType != 'direct' || myId == null || myId.isEmpty) return null;
    for (final member in members) {
      if (member.id != myId) return member;
    }
    return null;
  }

  factory RecentChat.fromJson(Map<String, dynamic> json) =>
      _$RecentChatFromJson(json);

  Map<String, dynamic> toJson() => _$RecentChatToJson(this);

  RecentChat copyWith({
    String? id,
    String? chatType,
    String? spaceId,
    dynamic activeCall,
    DateTime? deletedAt,
    DateTime? createdAt,
    String? name,
    String? imageUrl,
    List<ChatMember>? members,
    DateTime? lastActivityAt,
    ChatMessageModel? lastMessage,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    int? unreadCount,
    // Backward compatibility for properties updated individually:
    String? lastMessageContent,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
  }) {
    return RecentChat(
      id: id ?? this.id,
      chatType: chatType ?? this.chatType,
      spaceId: spaceId ?? this.spaceId,
      activeCall: activeCall ?? this.activeCall,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      members: members ?? this.members,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastMessage:
          lastMessage ??
          ((lastMessageContent != null ||
                  lastMessageAt != null ||
                  lastMessageSenderId != null)
              ? ChatMessageModel(
                  id: this.lastMessage?.id ?? '',
                  chatId: this.lastMessage?.chatId ?? '',
                  senderId:
                      lastMessageSenderId ?? this.lastMessage?.senderId ?? '',
                  senderName: this.lastMessage?.senderName ?? '',
                  messageType:
                      this.lastMessage?.messageType ?? MessageType.text,
                  content:
                      lastMessageContent ?? this.lastMessage?.content ?? '',
                  media: this.lastMessage?.media ?? const MessageMedia(),
                  mentions: this.lastMessage?.mentions ?? [],
                  forwarded: this.lastMessage?.forwarded ?? false,
                  edited: this.lastMessage?.edited ?? false,
                  status: this.lastMessage?.status ?? MessageStatus.sent,
                  isPinned: this.lastMessage?.isPinned ?? false,
                  deletedForEveryone:
                      this.lastMessage?.deletedForEveryone ?? false,
                  deletedForMe: this.lastMessage?.deletedForMe ?? [],
                  createdAt:
                      lastMessageAt ??
                      this.lastMessage?.createdAt ??
                      DateTime.now(),
                  updatedAt: this.lastMessage?.updatedAt ?? DateTime.now(),
                )
              : this.lastMessage),
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
