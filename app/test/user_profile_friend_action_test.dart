import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/features/users/screens/user_profile_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/recent_chat.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/providers/providers.dart';

class _FakeFriendProvider extends FriendProvider {
  _FakeFriendProvider(this._status, SocketService socket, {this.loaded = true})
    : super(socketService: socket);

  final FriendshipStatus Function(String peerId) _status;
  final bool loaded;
  final List<String> sentTo = [];

  @override
  bool get hasLoadedFriends => loaded;

  @override
  FriendshipStatus getFriendshipStatus(String peerId) => _status(peerId);

  @override
  Future<void> loadFriendsAndRequests({bool isSilent = false}) async {}

  @override
  Future<void> sendRequest(String receiverId) async => sentTo.add(receiverId);
}

class _FakeAuthProvider extends AuthProvider {
  @override
  UserModel? get user => UserModel(id: 'me', name: 'me');
}

void main() {
  final peer = UserModel(id: 'peer1', name: 'asha');

  /// A direct chat the way the server actually sends one: no members, so the
  /// peer is only reachable through the last message's sender.
  RecentChat memberlessChat({required String id, required String senderId}) =>
      RecentChat(
        id: id,
        chatType: 'direct',
        createdAt: DateTime(2026, 1, 1),
        name: 'asha',
        imageUrl: '',
        members: const [],
        isPinned: false,
        isMuted: false,
        isArchived: false,
        unreadCount: 0,
      ).copyWith(lastMessageSenderId: senderId, lastMessageContent: 'hi');

  Future<_FakeFriendProvider> pumpProfile(
    WidgetTester tester, {
    FriendshipStatus status = FriendshipStatus.none,
    Set<String> friendIds = const {},
    UserModel? user,
    String? chatId,
    List<RecentChat> chats = const [],
    double textScale = 1.0,
    bool friendsLoaded = true,
  }) async {
    final socket = SocketService();
    final friends = _FakeFriendProvider(
      (peerId) =>
          friendIds.contains(peerId) ? FriendshipStatus.accepted : status,
      socket,
      loaded: friendsLoaded,
    );
    addTearDown(friends.dispose);

    final chatProvider = ChatProvider(
      chatService: ChatService(),
      socketService: socket,
      user: null,
    );
    chatProvider.user = UserModel(id: 'me', name: 'me');
    chatProvider.recentChats = chats;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SocketService>.value(value: socket),
          ChangeNotifierProvider<FriendProvider>.value(value: friends),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => _FakeAuthProvider(),
          ),
          ChangeNotifierProvider<BlockProvider>(create: (_) => BlockProvider()),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: UserProfileScreen(user: user ?? peer, chatId: chatId),
          ),
        ),
      ),
    );
    await tester.pump();
    return friends;
  }

  testWidgets('a non-friend gets an Add Friend action', (tester) async {
    final friends = await pumpProfile(tester);

    await tester.tap(find.text('Add Friend'));
    await tester.pump();

    expect(friends.sentTo, ['peer1']);
  });

  testWidgets('an already-sent request shows as pending, not tappable', (
    tester,
  ) async {
    final friends = await pumpProfile(tester, status: FriendshipStatus.sent);

    expect(find.text('Requested'), findsOneWidget);
    await tester.tap(find.text('Requested'));
    await tester.pump();

    expect(friends.sentTo, isEmpty);
  });

  testWidgets('four actions still fit a narrow screen at a large font', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpProfile(tester, textScale: 1.5);

    // A RenderFlex overflow lands here rather than failing the pump.
    expect(tester.takeException(), isNull);
  });

  testWidgets('an existing friend gets no friendship action', (tester) async {
    await pumpProfile(tester, friendIds: {'peer1'});

    expect(find.text('Add Friend'), findsNothing);
    expect(find.text('Requested'), findsNothing);
    expect(find.text('Accept'), findsNothing);
    // The regular actions are still there.
    expect(find.text('Message'), findsOneWidget);
  });

  testWidgets('nothing is offered before the friends list has loaded', (
    tester,
  ) async {
    // The list is empty here only because it hasn't been fetched — the same
    // shape a real friend presents in the moment before the fetch lands.
    await pumpProfile(tester, friendsLoaded: false);

    expect(find.text('Add Friend'), findsNothing);
    expect(find.text('Message'), findsOneWidget);
  });

  group('when the chat handed over a user with no id', () {
    testWidgets('an existing friend still gets no Add Friend button', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        friendIds: {'peer1'},
        user: UserModel(id: '', name: 'asha'),
        chatId: 'chat1',
        chats: [memberlessChat(id: 'chat1', senderId: 'peer1')],
      );

      expect(find.text('Add Friend'), findsNothing);
    });

    testWidgets('a non-friend request carries the resolved id', (tester) async {
      final friends = await pumpProfile(
        tester,
        user: UserModel(id: '', name: 'asha'),
        chatId: 'chat1',
        chats: [memberlessChat(id: 'chat1', senderId: 'peer1')],
      );

      await tester.tap(find.text('Add Friend'));
      await tester.pump();

      expect(friends.sentTo, ['peer1']);
    });

    testWidgets('no action at all when the peer cannot be resolved', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        user: UserModel(id: '', name: 'asha'),
        chatId: 'chat1',
        // Last word was ours, so the sender is us — the peer is unknowable.
        chats: [memberlessChat(id: 'chat1', senderId: 'me')],
      );

      expect(find.text('Add Friend'), findsNothing);
      expect(find.text('Message'), findsOneWidget);
    });
  });
}
