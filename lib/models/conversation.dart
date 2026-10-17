class Conversation {
  final int id;
  final String type; // direct, group
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final int? otherUserId;

  Conversation({
    required this.id,
    required this.type,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    this.otherUserId,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] is int ? json['id'] : int.parse((json['id'] ?? 0).toString()),
      type: json['type'] ?? 'direct',
      name: json['name'] ?? 'Chat',
      avatarUrl: json['avatar_url'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
      unreadCount: json['unread_count'] != null ? int.parse(json['unread_count'].toString()) : 0,
      otherUserId: json['other_user_id'] != null ? int.parse(json['other_user_id'].toString()) : null,
    );
  }
}
