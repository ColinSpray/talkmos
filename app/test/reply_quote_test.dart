import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/features/chats/widgets/chat_bubble.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'package:talkmos/models/chat_message_model.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/providers/chat_provider.dart';

ChatMessageModel _message({
  required String id,
  required String content,
  String senderName = 'Nitish Vishwakarma',
  MessageType type = MessageType.text,
  String? replyTo,
}) {
  final at = DateTime(2026, 9, 15, 13, 44);
  return ChatMessageModel(
    id: id,
    chatId: 'c1',
    senderId: 'u1',
    senderName: senderName,
    messageType: type,
    content: content,
    media: const MessageMedia(),
    mentions: const [],
    forwarded: false,
    edited: false,
    status: MessageStatus.sent,
    isPinned: false,
    deletedForEveryone: false,
    deletedForMe: const [],
    replyTo: replyTo,
    createdAt: at,
    updatedAt: at,
  );
}

/// The bubble itself — the box carrying the BubbleShape.
Size _bubbleSize(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w is Container && w.decoration is ShapeDecoration,
  );
  return tester.getSize(finder.first);
}

/// The ceiling a bubble is allowed to reach, read from the app that was
/// actually pumped rather than assumed from the surface size.
late double bubbleCeiling;

Future<void> _pump(
  WidgetTester tester, {
  required ChatMessageModel message,
  ChatMessageModel? repliedMessage,
  VoidCallback? onReplyTap,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
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
        home: Builder(
          builder: (context) {
            bubbleCeiling = MediaQuery.of(context).size.width * 0.85;
            return Scaffold(
              body: SingleChildScrollView(
                child: ChatBubble(
                  message: message,
                  repliedMessage: repliedMessage,
                  isMe: true,
                  theme: ThemeData.light(),
                  onReplyTap: onReplyTap,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a quote sizes to its own text, not the whole bubble width', (
    tester,
  ) async {
    await _pump(
      tester,
      message: _message(id: 'm2', content: 'Hi', replyTo: 'm1'),
      repliedMessage: _message(id: 'm1', content: 'Hi'),
    );

    // The quote used to push the bubble to its ceiling no matter how little
    // it had to say.
    expect(_bubbleSize(tester).width, lessThan(bubbleCeiling * 0.9));
  });

  testWidgets('a long quote still stops at the bubble ceiling', (tester) async {
    await _pump(
      tester,
      message: _message(id: 'm2', content: 'Hi', replyTo: 'm1'),
      repliedMessage: _message(
        id: 'm1',
        content:
            'a quoted line far longer than any bubble is allowed to be, '
            'going on well past the edge of the screen',
      ),
    );

    expect(_bubbleSize(tester).width, lessThanOrEqualTo(bubbleCeiling));
  });

  testWidgets('tapping the quote asks for the original', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      message: _message(id: 'm2', content: 'Hi', replyTo: 'm1'),
      repliedMessage: _message(id: 'm1', content: 'Hi'),
      onReplyTap: () => tapped = true,
    );

    await tester.tap(find.text('Nitish Vishwakarma'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
