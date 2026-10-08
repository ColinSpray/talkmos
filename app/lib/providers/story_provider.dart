import 'package:flutter/foundation.dart';
import '../features/stories/services/story_service.dart';
import '../features/chats/services/chat_service/chat_service.dart';
import '../models/story_group_model.dart';
import '../models/story_model.dart';

/// One not-yet-uploaded story, ready to hand to [StoryProvider.uploadAndCreateStories].
class StoryUploadItem {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final String mediaType; // 'image' | 'video'
  final String? caption;

  const StoryUploadItem({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.mediaType,
    this.caption,
  });
}

class StoryProvider extends ChangeNotifier {
  final StoryService _storyService = StoryService();
  final ChatService _chatService = ChatService();

  List<StoryGroupModel> _storiesFeed = [];
  List<StoryModel> _discoverStories = [];
  bool _isLoadingFeed = false;
  bool _isLoadingDiscover = false;
  bool _isPostingStory = false;
  String? _error;

  List<StoryGroupModel> get storiesFeed => _storiesFeed;
  List<StoryModel> get discoverStories => _discoverStories;
  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingDiscover => _isLoadingDiscover;
  bool get isPostingStory => _isPostingStory;
  String? get error => _error;

  Future<void> loadStoriesFeed() async {
    _isLoadingFeed = true;
    notifyListeners();
    try {
      _storiesFeed = await _storyService.getStoriesFeed();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading stories feed: $e');
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  Future<void> loadDiscoverStories({String? category}) async {
    _isLoadingDiscover = true;
    notifyListeners();
    try {
      _discoverStories = await _storyService.getDiscoverFeed(
        category: category,
      );
    } catch (e) {
      debugPrint('Error loading discover stories: $e');
    } finally {
      _isLoadingDiscover = false;
      notifyListeners();
    }
  }

  Future<void> uploadAndCreateStories(
    List<StoryUploadItem> items, {
    String? category,
  }) async {
    if (items.isEmpty) return;
    _isPostingStory = true;
    notifyListeners();
    try {
      for (final item in items) {
        final mediaUrl = await _chatService.uploadFileToCloud(
          item.bytes,
          item.fileName,
          item.mimeType,
        );
        await _storyService.createStory(
          mediaUrl: mediaUrl,
          mediaType: item.mediaType,
          caption: item.caption,
          category: category,
        );
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error posting stories: $e');
    } finally {
      await loadStoriesFeed();
      await loadDiscoverStories();
      _isPostingStory = false;
      notifyListeners();
    }
  }

  Future<void> viewStory(String storyId) async {
    await _storyService.viewStory(storyId);
    await loadStoriesFeed();
  }

  Future<bool> deleteStory(String storyId) async {
    final success = await _storyService.deleteStory(storyId);
    if (success) {
      await loadStoriesFeed();
      await loadDiscoverStories();
    }
    return success;
  }
}
