import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/calls/services/call_signaling/call_signaling_service.dart';
import 'package:talkmos/features/calls/widgets/add_member_sheet.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/features/chats/utils/contact_candidates.dart';
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

  @override
  Future<void> loadRecentChats({bool force = false}) async {}
}

void main() {
  RecentChat directChat(String peerId, String name, String myId) => RecentChat(
    id: 'chat_$peerId',
    chatType: 'direct',
    createdAt: DateTime(2026, 1, 1),
    name: name,
    imageUrl: '',
    members: [
      ChatMember(id: myId, name: 'me'),
      ChatMember(id: peerId, name: name),
    ],
    isPinned: false,
    isMuted: false,
    isArchived: false,
    unreadCount: 0,
  );

  group('contactCandidates exclusion', () {
    test('drops ids already in the call', () {
      final all = contactCandidates(
        friends: const [
          FriendModel(id: 'f1', name: 'asha'),
          FriendModel(id: 'f2', name: 'ravi'),
        ],
        chats: [directChat('p9', 'public guy', 'me')],
        myId: 'me',
        exclude: const {'f1', 'p9'},
      );

      expect(all.map((f) => f.id), ['f2']);
    });

    test('excluding nobody keeps everybody', () {
      final all = contactCandidates(
        friends: const [FriendModel(id: 'f1', name: 'asha')],
        chats: [directChat('p9', 'public guy', 'me')],
        myId: 'me',
      );

      expect(all.map((f) => f.id), ['f1', 'p9']);
    });
  });

  Future<void> openSheet(
    WidgetTester tester, {
    List<FriendModel> friends = const [],
    List<RecentChat> chats = const [],
  }) async {
    final socket = SocketService();
    final chatProvider = _FakeChatProvider(socket);
    chatProvider.user = UserModel(id: 'me', name: 'me');
    chatProvider.recentChats = chats;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SocketService>.value(value: socket),
          ChangeNotifierProvider<FriendProvider>(
            create: (_) => _FakeFriendProvider(friends, socket),
          ),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAddMemberSheet(
                    context,
                    signalingService: CallSignalingService(),
                  ),
                  child: const Text('add'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
  }

  testWidgets('a non-friend chat partner can be invited to the call', (
    tester,
  ) async {
    await openSheet(
      tester,
      friends: const [FriendModel(id: 'f1', name: 'asha')],
      chats: [directChat('p9', 'public guy', 'me')],
    );

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Public Guy'), findsOneWidget);
    expect(find.text('No one available to invite'), findsNothing);
  });

  testWidgets('the empty state shows only when there is truly nobody', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('No one available to invite'), findsOneWidget);
  });
}
