import 'api_config.dart';

class ApiEndpoints {
  // ─── AUTH ENDPOINTS ──────────────────────────────────────────────────────────
  static Uri get register => Uri.parse('${ApiConfig.authUrl}/register');
  static Uri get login => Uri.parse('${ApiConfig.authUrl}/login');
  static Uri get authProfile => Uri.parse('${ApiConfig.authUrl}/');
  static Uri get forgotPassword =>
      Uri.parse('${ApiConfig.authUrl}/forgot-password');
  static Uri get resetPassword =>
      Uri.parse('${ApiConfig.authUrl}/reset-password');
  static Uri get fcmToken => Uri.parse('${ApiConfig.authUrl}/fcm-token');
  static Uri get googleLogin => Uri.parse('${ApiConfig.authUrl}/google');
  static Uri get sendPhoneOtp =>
      Uri.parse('${ApiConfig.authUrl}/phone/send-otp');
  static Uri get verifyPhoneOtp =>
      Uri.parse('${ApiConfig.authUrl}/phone/verify-otp');
  static Uri get logout => Uri.parse('${ApiConfig.authUrl}/logout');
  static Uri get devices => Uri.parse('${ApiConfig.authUrl}/devices');
  static Uri device(String deviceId) =>
      Uri.parse('${ApiConfig.authUrl}/devices/$deviceId');

  // ─── KEY ENDPOINTS ───────────────────────────────────────────────────────────
  static Uri get messageKey => Uri.parse('${ApiConfig.keysUrl}/message');

  // ─── FRIEND ENDPOINTS ────────────────────────────────────────────────────────
  static Uri get friendRequests =>
      Uri.parse('${ApiConfig.userSearchUrl}/friend-requests');
  static Uri get pendingFriendRequests =>
      Uri.parse('${ApiConfig.userSearchUrl}/friend-requests/pending');
  static Uri friendRequest(String requestId) =>
      Uri.parse('${ApiConfig.userSearchUrl}/friend-requests/$requestId');
  static Uri get friends => Uri.parse('${ApiConfig.userSearchUrl}/friends');

  /// Matches a device phone book against Talkmos accounts.
  static Uri get matchContacts =>
      Uri.parse('${ApiConfig.userSearchUrl}/contacts/match');

  /// Public profile lookup by id — used to resolve a chat deep link.
  static Uri userById(String userId) =>
      Uri.parse('${ApiConfig.userSearchUrl}/$userId');

  // ─── NEARBY ENDPOINTS ────────────────────────────────────────────────────────
  /// Opt in or out of proximity discovery.
  static Uri get nearbySettings =>
      Uri.parse('${ApiConfig.userSearchUrl}/nearby/settings');

  /// Asks who is around, refreshing this device's position in the same call.
  static Uri get nearbyHeartbeat =>
      Uri.parse('${ApiConfig.userSearchUrl}/nearby/heartbeat');

  static Uri get nearbyPing =>
      Uri.parse('${ApiConfig.userSearchUrl}/nearby/ping');
  static Uri get nearbyRequest =>
      Uri.parse('${ApiConfig.userSearchUrl}/nearby/request');

  // ─── BLOCKING ENDPOINTS ──────────────────────────────────────────────────────
  static Uri get blockedUsers =>
      Uri.parse('${ApiConfig.userSearchUrl}/blocked');
  static Uri blockUser(String userId) =>
      Uri.parse('${ApiConfig.userSearchUrl}/block/$userId');
  static Uri unblockUser(String userId) =>
      Uri.parse('${ApiConfig.userSearchUrl}/unblock/$userId');

  // ─── STORY ENDPOINTS ─────────────────────────────────────────────────────────
  static Uri get storyFeed => Uri.parse('${ApiConfig.storyUrl}/feed');
  static Uri get discoverStories => Uri.parse('${ApiConfig.storyUrl}/discover');
  static Uri get stories => Uri.parse(ApiConfig.storyUrl);

  /// A single story by id — used to resolve a story deep link.
  static Uri storyById(String storyId) =>
      Uri.parse('${ApiConfig.storyUrl}/$storyId');
  static Uri viewStory(String storyId) =>
      Uri.parse('${ApiConfig.storyUrl}/$storyId/view');
  static Uri deleteStory(String storyId) =>
      Uri.parse('${ApiConfig.storyUrl}/$storyId');
  static Uri storyViews(String storyId) =>
      Uri.parse('${ApiConfig.storyUrl}/$storyId/views');

  // ─── PROFILE ENDPOINTS ───────────────────────────────────────────────────────
  static Uri get profile => Uri.parse(ApiConfig.profileUrl);
  static Uri get settings => Uri.parse('${ApiConfig.profileUrl}/settings');
  static Uri get subscription =>
      Uri.parse('${ApiConfig.profileUrl}/subscription');

  // ─── CHAT ENDPOINTS ──────────────────────────────────────────────────────────
  static Uri get dashboard => Uri.parse('${ApiConfig.chatUrl}/dashboard');
  static Uri get conversations =>
      Uri.parse('${ApiConfig.chatUrl}/conversations');

  /// Only the chats the user has archived.
  static Uri get archivedConversations =>
      Uri.parse('${ApiConfig.chatUrl}/conversations?archivedOnly=true');
  static Uri conversation(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId');
  static Uri conversationRead(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/read');
  static Uri leaveConversation(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/leave');
  static Uri conversationPermissions(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/permissions');
  static Uri conversationPreferences(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/preferences');
  static Uri conversationMembers(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/members');
  static Uri conversationMember(String chatId, String userId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/members/$userId');
  static Uri messages(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/messages');
  static Uri sharedMedia(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/media');
  static Uri reactToMessage(String messageId) =>
      Uri.parse('${ApiConfig.chatUrl}/messages/$messageId/react');
  static Uri starMessage(String messageId) =>
      Uri.parse('${ApiConfig.chatUrl}/messages/$messageId/star');
  static Uri pinMessage(String messageId) =>
      Uri.parse('${ApiConfig.chatUrl}/messages/$messageId/pin');
  static Uri conversationPinnedMessages(String chatId) =>
      Uri.parse('${ApiConfig.chatUrl}/conversations/$chatId/pinned-messages');
  static Uri message(String messageId) =>
      Uri.parse('${ApiConfig.chatUrl}/messages/$messageId');
  static Uri deliverMessage(String messageId) =>
      Uri.parse('${ApiConfig.chatUrl}/messages/$messageId/deliver');
  static Uri get mediaUpload => Uri.parse('${ApiConfig.chatUrl}/media/upload');
  static Uri get communities => Uri.parse('${ApiConfig.chatUrl}/communities');
  static Uri joinCommunity(String communityId) =>
      Uri.parse('${ApiConfig.chatUrl}/communities/$communityId/join');
  static Uri leaveCommunity(String communityId) =>
      Uri.parse('${ApiConfig.chatUrl}/communities/$communityId/leave');
  static Uri communityMembers(String communityId) =>
      Uri.parse('${ApiConfig.chatUrl}/communities/$communityId/members');

  /// Public preview (no membership required) — used to resolve an invite link.
  static Uri communityPreview(String communityId) =>
      Uri.parse('${ApiConfig.chatUrl}/communities/$communityId/preview');

  /// POST only. `GET /chat/meetings` 404s on the deployed backend, but the POST
  /// this is used for was never exercised — writes are not probed.
  static Uri get meetings => Uri.parse('${ApiConfig.chatUrl}/meetings');
  static Uri communityEvents(String communityId) =>
      Uri.parse('${ApiConfig.chatUrl}/communities/$communityId/events');

  // ─── TRANSLATION ENDPOINTS ───────────────────────────────────────────────
  static Uri get translate => Uri.parse(ApiConfig.translateUrl);

}
