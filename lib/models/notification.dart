class AppNotification {
  final int id;
  final int actorId;
  final String actorUsername;
  final String actorFullName;
  final String? actorAvatarUrl;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.actorId,
    required this.actorUsername,
    required this.actorFullName,
    this.actorAvatarUrl,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.parse((json['id'] ?? 0).toString()),
      actorId: json['actor_id'] is int ? json['actor_id'] : int.parse((json['actor_id'] ?? 0).toString()),
      actorUsername: json['username'] ?? '',
      actorFullName: json['full_name'] ?? json['username'] ?? 'User',
      actorAvatarUrl: json['avatar_url'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
