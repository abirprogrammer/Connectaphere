class ApiConstants {
  // Base URL pointing to blood_app_api directory
  static const String baseUrl = 'https://programmingpulse.xyz/blood_app_api';

  // Auth Endpoints (Standalone PHP Files)
  static const String register = '/registers.php';
  static const String login = '/login.php';
  static const String logout = '/auth/logout';
  static const String resetPassword = '/auth/reset-password';

  // User Profile Endpoints
  static const String profile = '/profile.php';
  static const String searchUsers = '/user/search';

  // Friends Endpoints
  static const String sendFriendRequest = '/friends/request';
  static const String respondFriendRequest = '/friends/respond';
  static const String listFriends = '/friends/list';
  static const String pendingFriendRequests = '/friends/pending';
  static const String removeFriend = '/friends/remove';

  // Posts Endpoints
  static const String posts = '/posts.php';
  static const String reels = '/videos.php';
  static const String savePost = '/save_post.php';
  static const String toggleReaction = '/reactions.php';
  static const String comments = '/comments.php';

  // Stories
  static const String stories = '/stories.php';
  static const String viewStory = '/stories/view';

  // Media
  static const String uploadMedia = '/upload.php';

  // Messaging & Calls
  static const String conversations = '/conversations';
  static const String messages = '/messages';
  static const String initiateCall = '/calls/initiate';
  static const String respondCall = '/calls/respond';

  // Groups & Notifications & Settings
  static const String groups = '/groups';
  static const String joinGroup = '/groups/join';
  static const String notifications = '/notifications';
  static const String deviceToken = '/device-token';
  static const String updateTheme = '/settings/theme';
  static const String deleteAccount = '/settings/account';
}
