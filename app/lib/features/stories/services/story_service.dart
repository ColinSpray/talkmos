import 'dart:convert';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/http_service.dart';
import '../../../models/story_model.dart';
import '../../../models/story_group_model.dart';

class StoryService {
  Future<List<StoryGroupModel>> getStoriesFeed() async {
    try {
      final response = await HttpService.get(ApiEndpoints.storyFeed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final List<dynamic> data = body['data'];
        return data
            .map(
              (item) =>
                  StoryGroupModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      } else {
        throw body['message'] ?? 'Failed to fetch stories feed';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StoryModel>> getDiscoverFeed({String? category}) async {
    final queryParams = {if (category != null) 'category': category};
    final uri = ApiEndpoints.discoverStories.replace(
      queryParameters: queryParams,
    );

    try {
      final response = await HttpService.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final List<dynamic> data = body['data'];
        return data
            .map((item) => StoryModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        throw body['message'] ?? 'Failed to fetch discover stories';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<StoryModel> createStory({
    required String mediaUrl,
    required String mediaType,
    String? caption,
    String? category,
  }) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.stories,
        body: {
          'mediaUrl': mediaUrl,
          'mediaType': mediaType,
          'caption': caption ?? '',
          'category': category ?? 'Friends',
        },
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return StoryModel.fromJson(Map<String, dynamic>.from(body['data']));
      } else {
        throw body['message'] ?? 'Failed to create story';
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Single-story fetch — used to resolve a story deep link
  /// (`talkmos://story/<storyId>`) without needing the full feed loaded.
  Future<StoryModel> getStoryById(String storyId) async {
    try {
      final response = await HttpService.get(ApiEndpoints.storyById(storyId));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return StoryModel.fromJson(Map<String, dynamic>.from(body['data']));
      } else {
        throw body['message'] ?? 'Story not found or expired';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> viewStory(String storyId) async {
    try {
      final response = await HttpService.post(ApiEndpoints.viewStory(storyId));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return response.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      final response = await HttpService.delete(
        ApiEndpoints.deleteStory(storyId),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return response.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getStoryViews(String storyId) async {
    try {
      final response = await HttpService.get(ApiEndpoints.storyViews(storyId));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return body['data'] as List<dynamic>;
      } else {
        throw body['message'] ?? 'Failed to fetch story views';
      }
    } catch (e) {
      rethrow;
    }
  }
}
