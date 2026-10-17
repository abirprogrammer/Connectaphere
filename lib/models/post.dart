class PostMedia {
  final int id;
  final String mediaType; // image or video
  final String url;
  final String? thumbnailUrl;

  PostMedia({
    required this.id,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      mediaType: json['media_type'] ?? 'image',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
    );
  }
}

class Post {
  final int id;
  final int userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String? content;
  final String privacy;
  final int reactionsCount;
  final int commentsCount;
  final int sharesCount;
  final String? userReaction;
  final bool isSaved;
  final List<PostMedia> media;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.content,
    required this.privacy,
    required this.reactionsCount,
    required this.commentsCount,
    required this.sharesCount,
    this.userReaction,
    required this.isSaved,
    required this.media,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    var mediaList = <PostMedia>[];
    if (json['media'] != null && json['media'] is List) {
      mediaList = (json['media'] as List).map((m) => PostMedia.fromJson(m)).toList();
    }

    return Post(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? 'User',
      avatarUrl: json['avatar_url'],
      content: json['content'],
      privacy: json['privacy'] ?? 'public',
      reactionsCount: json['reactions_count'] != null ? int.parse(json['reactions_count'].toString()) : 0,
      commentsCount: json['comments_count'] != null ? int.parse(json['comments_count'].toString()) : 0,
      sharesCount: json['shares_count'] != null ? int.parse(json['shares_count'].toString()) : 0,
      userReaction: json['user_reaction'],
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
      media: mediaList,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
