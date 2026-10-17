class Comment {
  final int id;
  final int postId;
  final int userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      postId: json['post_id'] is int ? json['post_id'] : int.parse(json['post_id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? 'User',
      avatarUrl: json['avatar_url'],
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
