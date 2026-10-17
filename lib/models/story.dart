class StoryItem {
  final int id;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final bool isViewed;

  StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.isViewed,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'] is int ? json['id'] : int.parse((json['id'] ?? 0).toString()),
      mediaUrl: json['media_url'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      caption: json['caption'],
      isViewed: json['is_viewed'] == true || json['is_viewed'] == 1,
    );
  }
}

class UserStoryGroup {
  final int userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final List<StoryItem> stories;

  UserStoryGroup({
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.stories,
  });

  factory UserStoryGroup.fromJson(Map<String, dynamic> json) {
    var list = <StoryItem>[];
    final storiesData = json['stories'];
    if (storiesData != null && storiesData is List) {
      list = storiesData.map((s) => StoryItem.fromJson(s)).toList();
    }
    return UserStoryGroup(
      userId: json['user_id'] is int ? json['user_id'] : int.parse((json['user_id'] ?? 0).toString()),
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? 'User',
      avatarUrl: json['avatar_url'],
      stories: list,
    );
  }
}
