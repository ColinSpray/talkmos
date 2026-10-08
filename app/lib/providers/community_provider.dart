import 'package:flutter/foundation.dart';
import '../features/chats/services/chat_service/chat_service.dart';
import '../models/community_model.dart';

class CommunityProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<CommunityModel> _communities = [];
  bool _isLoading = false;
  String? _error;

  List<CommunityModel> get communities => _communities;
  List<CommunityModel> get yourCommunities =>
      _communities.where((c) => c.isMember).toList();
  List<CommunityModel> get discoverCommunities =>
      _communities.where((c) => !c.isMember).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCommunities({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _chatService.getCommunities(category: category);
      _communities = raw
          .map((c) => CommunityModel.fromJson(Map<String, dynamic>.from(c)))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading communities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCommunity({
    required String name,
    String? description,
    String? category,
    String? imageUrl,
  }) async {
    await _chatService.createCommunity(
      name: name,
      description: description,
      category: category,
      imageUrl: imageUrl,
    );
    await loadCommunities();
  }

  Future<void> joinCommunity(String chatId) async {
    await _chatService.joinCommunity(chatId);
    await loadCommunities();
  }

  Future<void> leaveCommunity(String chatId) async {
    await _chatService.leaveCommunity(chatId);
    await loadCommunities();
  }
}
