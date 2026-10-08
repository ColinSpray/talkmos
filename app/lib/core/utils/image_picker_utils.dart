import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import '../../features/chats/services/chat_service/chat_service.dart';
import '../services/file_naming_service.dart';

Future<XFile?> pickImageFrom(ImageSource source, {int? imageQuality}) {
  return ImagePicker().pickImage(source: source, imageQuality: imageQuality);
}

Future<String> uploadPickedImage(XFile file) async {
  final bytes = await file.readAsBytes();
  final mimeType = file.mimeType ?? 'image/jpeg';
  return uploadImageBytes(bytes, mimeType: mimeType, fileName: file.name);
}

/// Uploads already-in-memory image bytes (e.g. after a crop, where the bytes
/// no longer match the originally picked file) via [ChatService].
Future<String> uploadImageBytes(
  Uint8List bytes, {
  required String mimeType,
  String fileName = 'image',
}) {
  final uploadName = FileNamingService.getUploadName(fileName, mimeType);
  return ChatService().uploadFileToCloud(bytes, uploadName, mimeType);
}
