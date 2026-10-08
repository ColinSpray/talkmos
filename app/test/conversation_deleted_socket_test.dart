import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/models/recent_chat.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/providers/chat_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The handler clears the chat's cached history, which goes through sqflite.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  RecentChat group(String id) => RecentChat(
    id: id,
    chatType: 'group',
    createdAt: DateTime(2026, 1, 1),
    name: 'Trip',
    imageUrl: '',
    isPinned: false,
    isMuted: false,
    isArchived: false,
    unreadCount: 0,
  );

  late SocketService socket;
  late ChatProvider provider;

  setUp(() {
    socket = SocketService();
    provider = ChatProvider(
      chatService: ChatService(),
      socketService: socket,
      user: UserModel(id: 'me', name: 'me'),
    );
  });

  tearDown(() => provider.dispose());

  test('the socket handler is wired once the user is known', () {
    expect(socket.onConversationDeleted, isNotNull);
  });

  test('a deleted group leaves the chat list', () {
    provider.recentChats = [group('g1'), group('g2')];

    socket.onConversationDeleted!('g1', 'owner1');

    expect(provider.recentChats.map((c) => c.conversationId), ['g2']);
  });

  test('it leaves the archived list too', () {
    provider.archivedChats = [group('g1')];

    socket.onConversationDeleted!('g1', 'owner1');

    expect(provider.archivedChats, isEmpty);
  });

  test('an unrelated chat id changes nothing', () {
    provider.recentChats = [group('g1')];

    socket.onConversationDeleted!('other', 'owner1');

    expect(provider.recentChats.map((c) => c.conversationId), ['g1']);
  });

  test('listeners are told, so an open chat screen can react', () {
    provider.recentChats = [group('g1')];
    var notifications = 0;
    provider.addListener(() => notifications++);

    socket.onConversationDeleted!('g1', 'owner1');

    expect(notifications, 1);
  });

  test('the close signal fires only for the chat on screen', () {
    provider.recentChats = [group('g1'), group('g2')];
    provider.activeChatId = 'g1';
    final signals = <String?>[];
    provider.addListener(() => signals.add(provider.deletedChatId));

    socket.onConversationDeleted!('g2', 'owner1');
    socket.onConversationDeleted!('g1', 'owner1');

    expect(signals, [null, 'g1']);
  });

  test('the signal does not linger after it is handled', () {
    provider.recentChats = [group('g1')];
    provider.activeChatId = 'g1';

    socket.onConversationDeleted!('g1', 'owner1');

    expect(provider.deletedChatId, isNull);
  });
}
