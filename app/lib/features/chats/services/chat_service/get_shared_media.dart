part of 'chat_service.dart';

extension ChatServiceGetSharedMedia on ChatService {
  /// [before] pages backward using the last item's `createdAt`.
  Future<SharedMediaPage> getSharedMedia(
    String chatId, {
    int limit = 30,
    DateTime? before,
  }) async {
    if (chatId.isEmpty) return const SharedMediaPage(items: [], total: 0);
    final queryParams = {
      'limit': '$limit',
      if (before != null) 'before': before.toUtc().toIso8601String(),
    };
    final uri = ApiEndpoints.sharedMedia(
      chatId,
    ).replace(queryParameters: queryParams);

    final response = await HttpService.get(uri);
    final body = _parseResponse(response);
    if (response.statusCode == 200 && body['success'] == true) {
      final List<dynamic> data = body['data'];
      return SharedMediaPage(
        items: data
            .map(
              (json) =>
                  SharedMediaItem.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList(),
        total: (body['total'] as num?)?.toInt() ?? 0,
      );
    }
    throw Exception(body['message'] ?? 'Failed to fetch shared media');
  }
}
