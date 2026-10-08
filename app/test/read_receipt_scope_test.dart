import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/providers/chat_provider.dart';

ChatMessageModel _mine(String id, String chatId, MessageStatus status) =>
    ChatMessageModel(
      id: id,
      chatId: chatId,
      senderId: 'me',
      senderName: 'Me',
      messageType: MessageType.text,
      content: 'hello',
      media: const MessageMedia(),
      mentions: const [],
      forwarded: false,
      edited: false,
      status: status,
      isPinned: false,
      deletedForEveryone: false,
      deletedForMe: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await dotenv.load(fileName: '.env');
  });

  ChatProvider build() {
    final socket = SocketService();
    final provider = ChatProvider(
      chatService: ChatService(),
      socketService: socket,
      user: UserModel(id: 'me', name: 'Me'),
    );
    provider.messages = {
      'chat-1': [_mine('m1', 'chat-1', MessageStatus.delivered)],
      'chat-2': [_mine('m2', 'chat-2', MessageStatus.delivered)],
    };
    return provider;
  }

  test('a read receipt only marks the chat it came from', () {
    final provider = build();
    final socket = provider.socketService;

    // The server sends { readerId, chatId }. The chatId used to be dropped on
    // the way through, so this single receipt marked every message this
    // account had sent — in every loaded chat — as read.
    socket.onMessagesRead!('peer', 'chat-1');

    expect(provider.messages['chat-1']!.first.status, MessageStatus.read);
    expect(
      provider.messages['chat-2']!.first.status,
      MessageStatus.delivered,
      reason: 'a receipt for chat-1 must not touch chat-2',
    );
  });

  test('a receipt for an unloaded chat changes nothing', () {
    final provider = build();
    var notified = 0;
    provider.addListener(() => notified++);

    provider.socketService.onMessagesRead!('peer', 'chat-unknown');

    expect(provider.messages['chat-1']!.first.status, MessageStatus.delivered);
    expect(provider.messages['chat-2']!.first.status, MessageStatus.delivered);
    expect(notified, 0, reason: 'no change means no rebuild');
  });

  test('a duplicate receipt does not notify a second time', () {
    final provider = build();
    provider.socketService.onMessagesRead!('peer', 'chat-1');

    var notified = 0;
    provider.addListener(() => notified++);
    provider.socketService.onMessagesRead!('peer', 'chat-1');

    expect(notified, 0, reason: 'already read — nothing to do');
  });

  test('status only ever moves forward', () {
    final provider = build();
    final socket = provider.socketService;

    socket.onMessageStatusChanged!('m1', MessageStatus.read);
    expect(provider.messages['chat-1']!.first.status, MessageStatus.read);

    // A late 'delivered' for a message already read must not walk it back.
    socket.onMessageStatusChanged!('m1', MessageStatus.delivered);
    expect(provider.messages['chat-1']!.first.status, MessageStatus.read);
  });

  test('a status change for an unknown message does not notify', () {
    final provider = build();
    var notified = 0;
    provider.addListener(() => notified++);

    provider.socketService.onMessageStatusChanged!('nope', MessageStatus.read);

    expect(notified, 0);
  });
}
