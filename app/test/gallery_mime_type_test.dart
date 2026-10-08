import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/controllers/chat_media_controller.dart';
import 'package:talkmos/features/chats/screens/media_preview_screen.dart';
import 'package:talkmos/core/services/file_naming_service.dart';

/// The gallery picker doesn't always report a MIME type, and on some devices
/// it can return documents. What the extension is read as decides how the file
/// is previewed, how it's sent, and what opens it later.
void main() {
  String guess(String name) => ChatMediaPicker.guessMimeTypeFromExtension(name);

  group('guessMimeTypeFromExtension', () {
    test('documents are not photos', () {
      expect(guess('report.pdf'), 'application/pdf');
      expect(guess('notes.docx'), 'application/octet-stream');
      expect(guess('books.epub'), 'application/octet-stream');
      expect(guess('archive.zip'), 'application/octet-stream');
    });

    test('images keep their own format', () {
      expect(guess('holiday.jpg'), 'image/jpeg');
      expect(guess('shot.PNG'), 'image/png');
      expect(guess('loop.gif'), 'image/gif');
      expect(guess('photo.heic'), 'image/heic');
    });

    test('videos are recognised', () {
      expect(guess('clip.mp4'), 'video/mp4');
      expect(guess('clip.MOV'), 'video/quicktime');
      expect(guess('clip.webm'), 'video/mp4');
    });

    test('audio is recognised', () {
      expect(guess('song.mp3'), 'audio/mpeg');
      expect(guess('voice.m4a'), 'audio/mp4');
    });

    test('a name with no extension is a document, not a photo', () {
      expect(guess('scan'), 'application/octet-stream');
    });
  });

  group('the knock-on effects of that guess', () {
    test('a PDF previews as a file, not an image', () {
      expect(previewKindFor(guess('report.pdf')), PreviewKind.file);
      expect(previewKindFor(guess('holiday.jpg')), PreviewKind.image);
      expect(previewKindFor(guess('clip.mp4')), PreviewKind.video);
    });

    test('a PDF keeps its extension through upload naming', () {
      final name = FileNamingService.getUploadName(
        'report.pdf',
        guess('report.pdf'),
      );

      // Named .jpg, it opens in an image viewer for the rest of its life.
      expect(name, endsWith('.pdf'));
      expect(name, startsWith('tm_file_'));
    });

    test('a photo is still named as an image', () {
      final name = FileNamingService.getUploadName(
        'holiday.jpg',
        guess('holiday.jpg'),
      );

      expect(name, endsWith('.jpg'));
      expect(name, startsWith('tm_image_'));
    });
  });
}
