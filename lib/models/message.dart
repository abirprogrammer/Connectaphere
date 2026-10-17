class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String messageType; // text, media, call_notice
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.messageType,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      conversationId: json['conversation_id'] is int ? json['conversation_id'] : int.parse(json['conversation_id'].toString()),
      senderId: json['sender_id'] is int ? json['sender_id'] : int.parse(json['sender_id'].toString()),
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? 'User',
      avatarUrl: json['avatar_url'],
      messageType: json['message_type'] ?? 'text',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
