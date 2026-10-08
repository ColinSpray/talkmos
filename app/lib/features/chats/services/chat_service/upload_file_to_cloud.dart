part of 'chat_service.dart';

extension ChatServiceUploadFileToCloud on ChatService {
  /// Uploads directly to the cloud provider (Cloudinary or S3) using the
  /// presigned params from [uploadMedia].
  Future<String> uploadFileToCloud(
    List<int> fileBytes,
    String fileName,
    String mimeType,
  ) async {
    final params = await uploadMedia(fileName: fileName, mimeType: mimeType);

    final uploadUrl = params['uploadUrl'] as String;
    final method = params['method'] as String;
    final fields = Map<String, dynamic>.from(params['fields'] ?? {});
    final headers = Map<String, String>.from(params['headers'] ?? {});
    final mediaUrl = params['mediaUrl'] as String;

    final uri = Uri.parse(uploadUrl);

    if (method == 'POST') {
      final request = http.MultipartRequest('POST', uri);

      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      request.headers.addAll(headers);

      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Direct upload failed: $body');
      }
      final delivered = _deliveredUrl(body);
      if (delivered != null) return delivered;
    } else if (method == 'PUT') {
      final response = await http.put(
        uri,
        body: fileBytes,
        headers: {'Content-Type': mimeType, ...headers},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Direct upload failed: ${response.body}');
      }
      final delivered = _deliveredUrl(response.body);
      if (delivered != null) return delivered;
    } else {
      throw Exception('Unsupported upload method: $method');
    }

    return mediaUrl;
  }

  /// The URL the provider says it will actually serve the file from.
  ///
  /// Preferred over the one the server predicts when it signed the upload,
  /// which guesses at two things it cannot know. It appends the original
  /// extension to a `raw` public_id that was created without one, and it uses
  /// the signing timestamp as the version rather than the version the upload
  /// is assigned. Both are wrong for documents — every one of them resolved to
  /// a 404 — and images only survived it because image delivery URLs tolerate
  /// a trailing extension.
  String? _deliveredUrl(String responseBody) {
    if (responseBody.isEmpty) return null;
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map) return null;
      final url = (decoded['secure_url'] ?? decoded['url'])?.toString();
      return (url != null && url.startsWith('http')) ? url : null;
    } catch (e) {
      debugPrint('[Upload] could not read delivery url: $e');
      return null;
    }
  }
}
