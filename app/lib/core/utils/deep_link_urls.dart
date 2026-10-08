class DeepLinkUrls {
  DeepLinkUrls._();

  static const _base = 'https://talkmos.com';

  static String chat(String userId) => '$_base/chat/$userId';
  static String story(String storyId) => '$_base/story/$storyId';
  static String invite(String communityId) => '$_base/invite/$communityId';
}
