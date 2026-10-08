// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageMedia _$MessageMediaFromJson(Map<String, dynamic> json) => MessageMedia(
  url: json['url'] as String? ?? '',
  thumbnail: json['thumbnail'] as String? ?? '',
  fileName: json['fileName'] as String? ?? '',
  mimeType: json['mimeType'] as String? ?? '',
  size: (json['size'] as num?)?.toInt() ?? 0,
  duration: (json['duration'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MessageMediaToJson(MessageMedia instance) =>
    <String, dynamic>{
      'url': instance.url,
      'thumbnail': instance.thumbnail,
      'fileName': instance.fileName,
      'mimeType': instance.mimeType,
      'size': instance.size,
      'duration': instance.duration,
    };

ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) =>
    ChatMessageModel(
      id: json['_id'] as String? ?? '',
      chatId: json['chatId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderAvatarUrl: json['senderAvatarUrl'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      messageType: $enumDecode(_$MessageTypeEnumMap, json['messageType']),
      content: json['content'] as String? ?? '',
      media: MessageMedia.fromJson(json['media'] as Map<String, dynamic>?),
      mentions:
          (json['mentions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      replyTo: json['replyTo'] as String?,
      forwarded: json['forwarded'] as bool? ?? false,
      edited: json['edited'] as bool? ?? false,
      editedAt: const LocalDateTimeConverterNullable().fromJson(
        json['editedAt'] as String?,
      ),
      status: $enumDecode(_$MessageStatusEnumMap, json['status']),
      isPinned: json['isPinned'] as bool? ?? false,
      pinnedAt: const LocalDateTimeConverterNullable().fromJson(
        json['pinnedAt'] as String?,
      ),
      deletedForEveryone: json['deletedForEveryone'] as bool? ?? false,
      deletedForMe:
          (json['deletedForMe'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      deletedAt: const LocalDateTimeConverterNullable().fromJson(
        json['deletedAt'] as String?,
      ),
      reactions: json['reactions'] as List<dynamic>? ?? const [],
      isStarred: json['isStarred'] as bool? ?? false,
      tempId: json['clientMessageId'] as String?,
      createdAt: const LocalDateTimeConverter().fromJson(
        json['createdAt'] as String,
      ),
      updatedAt: const LocalDateTimeConverter().fromJson(
        json['updatedAt'] as String,
      ),
    );

Map<String, dynamic> _$ChatMessageModelToJson(
  ChatMessageModel instance,
) => <String, dynamic>{
  '_id': instance.id,
  'chatId': instance.chatId,
  'senderId': instance.senderId,
  'senderName': instance.senderName,
  'senderAvatarUrl': instance.senderAvatarUrl,
  'receiverId': instance.receiverId,
  'messageType': _$MessageTypeEnumMap[instance.messageType]!,
  'content': instance.content,
  'media': instance.media,
  'mentions': instance.mentions,
  'replyTo': instance.replyTo,
  'forwarded': instance.forwarded,
  'edited': instance.edited,
  'editedAt': const LocalDateTimeConverterNullable().toJson(instance.editedAt),
  'status': _$MessageStatusEnumMap[instance.status]!,
  'isPinned': instance.isPinned,
  'pinnedAt': const LocalDateTimeConverterNullable().toJson(instance.pinnedAt),
  'deletedForEveryone': instance.deletedForEveryone,
  'deletedForMe': instance.deletedForMe,
  'deletedAt': const LocalDateTimeConverterNullable().toJson(
    instance.deletedAt,
  ),
  'reactions': instance.reactions,
  'isStarred': instance.isStarred,
  'clientMessageId': instance.tempId,
  'createdAt': const LocalDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const LocalDateTimeConverter().toJson(instance.updatedAt),
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.video: 'video',
  MessageType.audio: 'audio',
  MessageType.voice: 'voice',
  MessageType.file: 'file',
  MessageType.gif: 'gif',
  MessageType.sticker: 'sticker',
  MessageType.location: 'location',
  MessageType.contact: 'contact',
  MessageType.system: 'system',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
  MessageStatus.read: 'read',
  MessageStatus.failed: 'failed',
};
