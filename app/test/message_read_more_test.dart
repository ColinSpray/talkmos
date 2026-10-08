import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/features/chats/widgets/chat_bubble.dart';
import 'package:talkmos/features/chats/widgets/message_content/text_message_content.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/providers/chat_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await dotenv.load(fileName: '.env');
  });

  // Narrow enough that the sample paragraph wraps well past the collapse
  // limit, matching a real bubble's 85%-of-screen ceiling.
  const bubbleWidth = 250.0;

  final long = List.generate(
    40,
    (i) => 'line $i of a very long message',
  ).join(' ');
  const short = 'ok';

  Future<void> pump(
    WidgetTester tester,
    String content, {
    bool isExpanded = false,
    VoidCallback? onToggle,
    bool collapsible = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          // Mirrors the real bubble's home: a scrollable, so an expanded
          // message is free to run past the viewport as it does in the list.
          body: SingleChildScrollView(
            child: SizedBox(
              width: bubbleWidth,
              child: TextMessageContent(
                content: content,
                textColor: Colors.black,
                isExpanded: isExpanded,
                onToggleExpanded: collapsible ? (onToggle ?? () {}) : null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Text bodyOf(WidgetTester tester, String content) =>
      tester.widget<Text>(find.text(content));

  testWidgets('a short message gets no toggle', (tester) async {
    await pump(tester, short);

    expect(find.text('Read more'), findsNothing);
    expect(find.text('Read less'), findsNothing);
    expect(bodyOf(tester, short).maxLines, isNull);
  });

  testWidgets('a long message collapses behind Read more', (tester) async {
    await pump(tester, long);

    expect(find.text('Read more'), findsOneWidget);
    expect(bodyOf(tester, long).maxLines, TextMessageContent.collapsedMaxLines);
    expect(bodyOf(tester, long).overflow, TextOverflow.ellipsis);
  });

  testWidgets('tapping Read more reports the toggle', (tester) async {
    var taps = 0;
    await pump(tester, long, onToggle: () => taps++);

    await tester.tap(find.text('Read more'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('an expanded message shows everything and offers Read less', (
    tester,
  ) async {
    await pump(tester, long, isExpanded: true);

    expect(find.text('Read less'), findsOneWidget);
    expect(find.text('Read more'), findsNothing);
    expect(bodyOf(tester, long).maxLines, isNull);
  });

  testWidgets('without a toggle handler the text is never collapsed', (
    tester,
  ) async {
    await pump(tester, long, collapsible: false);

    expect(find.text('Read more'), findsNothing);
    expect(bodyOf(tester, long).maxLines, isNull);
  });

  testWidgets('collapsing keeps a long message off most of the screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pump(tester, long);
    final collapsed = tester.getSize(find.byType(TextMessageContent)).height;

    await pump(tester, long, isExpanded: true);
    final expanded = tester.getSize(find.byType(TextMessageContent)).height;

    expect(collapsed, lessThan(expanded));
    expect(collapsed, lessThan(360));
  });

  // The bubble lays text and the timestamp out with a Wrap, so the toggle has
  // to coexist with the meta row rather than push it somewhere unreachable.
  group('inside a real bubble', () {
    ChatMessageModel messageWith(String content) => ChatMessageModel(
      id: 'm1',
      chatId: 'c1',
      senderId: 'u1',
      senderName: 'Rahul',
      messageType: MessageType.text,
      content: content,
      media: const MessageMedia(),
      mentions: const [],
      forwarded: false,
      edited: false,
      status: MessageStatus.sent,
      isPinned: false,
      deletedForEveryone: false,
      deletedForMe: const [],
      createdAt: DateTime(2026, 8, 18, 17, 42),
      updatedAt: DateTime(2026, 8, 18, 17, 42),
    );

    Future<void> pumpBubble(
      WidgetTester tester,
      String content, {
      bool isExpanded = false,
      VoidCallback? onToggle,
    }) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = ChatProvider(
        chatService: ChatService(),
        socketService: SocketService(),
        user: UserModel(id: 'u1', name: 'Me'),
      );
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ChatBubble(
                  message: messageWith(content),
                  isMe: false,
                  theme: ThemeData.light(),
                  isExpanded: isExpanded,
                  onToggleExpanded: onToggle ?? () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a long message collapses and still shows its time', (
      tester,
    ) async {
      await pumpBubble(tester, long);

      expect(find.text('Read more'), findsOneWidget);
      expect(find.text('17:42'), findsOneWidget);
    });

    testWidgets('the toggle sits above the timestamp, not beside it', (
      tester,
    ) async {
      await pumpBubble(tester, long);

      final toggle = tester.getRect(find.text('Read more'));
      final time = tester.getRect(find.text('17:42'));

      expect(toggle.bottom, lessThanOrEqualTo(time.top + 1));
    });

    testWidgets('a short message keeps the time on the same line', (
      tester,
    ) async {
      await pumpBubble(tester, short);

      expect(find.text('Read more'), findsNothing);
      final body = tester.getRect(find.text(short));
      final time = tester.getRect(find.text('17:42'));
      // Inline: they overlap vertically instead of stacking.
      expect(time.top, lessThan(body.bottom));
    });
  });
}
