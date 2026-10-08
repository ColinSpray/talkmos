import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/screens/create_group_screen.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/friend_model.dart';
import 'package:talkmos/models/recent_chat.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/providers/providers.dart';

class _FakeFriendProvider extends FriendProvider {
  _FakeFriendProvider(this._friends, SocketService socket)
    : super(socketService: socket);

  final List<FriendModel> _friends;

  @override
  List<FriendModel> get friends => _friends;

  @override
  Future<void> loadFriendsAndRequests({bool isSilent = false}) async {}
}

class _FakeChatProvider extends ChatProvider {
  _FakeChatProvider(SocketService socket)
    : super(chatService: ChatService(), socketService: socket, user: null);

  int loadCalls = 0;

  @override
  Future<void> loadRecentChats({bool force = false}) async => loadCalls++;
}

void main() {
  RecentChat directChatWith(String peerId, String peerName, String myId) =>
      RecentChat(
        id: 'chat_$peerId',
        chatType: 'direct',
        createdAt: DateTime(2026, 1, 1),
        name: peerName,
        imageUrl: '',
        members: [
          ChatMember(id: myId, name: 'me'),
          ChatMember(id: peerId, name: peerName),
        ],
        isPinned: false,
        isMuted: false,
        isArchived: false,
        unreadCount: 0,
      );

  Future<_FakeChatProvider> pumpMembersStep(
    WidgetTester tester, {
    List<FriendModel> friends = const [],
    List<RecentChat> chats = const [],
    UserModel? me,
  }) async {
    final socket = SocketService();
    final chatProvider = _FakeChatProvider(socket);
    chatProvider.user = me;
    chatProvider.recentChats = chats;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SocketService>.value(value: socket),
          ChangeNotifierProvider<FriendProvider>(
            create: (_) => _FakeFriendProvider(friends, socket),
          ),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CreateGroupScreen(),
        ),
      ),
    );
    await tester.pump();

    // Step 1 → step 2: a name is all that gates "Next".
    await tester.enterText(find.byType(TextField).first, 'Trip');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    return chatProvider;
  }

  testWidgets('friends are listed on the member step', (tester) async {
    await pumpMembersStep(
      tester,
      friends: [
        const FriendModel(id: 'f1', name: 'asha'),
        const FriendModel(id: 'f2', name: 'ravi'),
      ],
    );

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
  });

  testWidgets('a non-friend chat partner is listed too', (tester) async {
    await pumpMembersStep(
      tester,
      friends: [const FriendModel(id: 'f1', name: 'asha')],
      chats: [directChatWith('p9', 'public guy', 'me')],
      me: UserModel(id: 'me', name: 'me'),
    );

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Public Guy'), findsOneWidget);
  });

  testWidgets('a chat partner is found without a members list', (tester) async {
    // What the server actually sends for direct chats today: no members, the
    // peer's identity only reachable through the last message's sender.
    await pumpMembersStep(
      tester,
      chats: [
        RecentChat(
          id: 'chat_p9',
          chatType: 'direct',
          createdAt: DateTime(2026, 1, 1),
          name: 'public guy',
          imageUrl: '',
          members: const [],
          isPinned: false,
          isMuted: false,
          isArchived: false,
          unreadCount: 0,
        ).copyWith(lastMessageSenderId: 'p9', lastMessageContent: 'hi'),
      ],
      me: UserModel(id: 'me', name: 'me'),
    );

    expect(find.text('Public Guy'), findsOneWidget);
  });

  testWidgets('friends still show when the chat list is empty', (tester) async {
    await pumpMembersStep(
      tester,
      friends: [const FriendModel(id: 'f1', name: 'asha')],
      chats: const [],
      me: UserModel(id: 'me', name: 'me'),
    );

    expect(find.text('Asha'), findsOneWidget);
  });
}
