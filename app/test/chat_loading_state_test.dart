import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talkmos/features/chats/services/chat_service/chat_service.dart';
import 'package:talkmos/features/chats/services/socket_service/socket_service.dart';
import 'package:talkmos/models/user_model.dart';
import 'package:talkmos/providers/chat_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await dotenv.load(fileName: '.env');
  });

  test('a chat reports loading before the cache read resolves', () {
    // A signed-in user matters: it is what makes getMessages await the offline
    // store. With no user that read is skipped and the gap this guards against
    // never opens.
    final provider = ChatProvider(
      chatService: ChatService(),
      socketService: SocketService(),
      user: UserModel(id: 'u1', name: 'Me'),
    );

    expect(provider.isLoadingMessagesFor('chat-1'), isFalse);

    // Deliberately not awaited. The screen builds on the very next frame, well
    // before the cache read resolves — if the flag is only set after that await,
    // the frame sees "not loading, no messages" and paints the empty state.
    // That flash is the bug.
    provider.getMessages('chat-1');

    expect(
      provider.isLoadingMessagesFor('chat-1'),
      isTrue,
      reason: 'loading must be set synchronously, before the cache read',
    );
    // Scoped to the chat that asked, so a slow load finishing for a chat the
    // user already left cannot clear the loading state of the one on screen.
    expect(provider.isLoadingMessagesFor('chat-2'), isFalse);
  });
}
