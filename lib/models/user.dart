class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final String? website;
  final int friendsCount;
  final int postsCount;
  final String relationship; // self, friends, pending, none

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.location,
    this.website,
    this.friendsCount = 0,
    this.postsCount = 0,
    this.relationship = 'none',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse((json['id'] ?? 0).toString()),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? 'User',
      avatarUrl: json['avatar_url'],
      coverUrl: json['cover_url'],
      bio: json['bio'],
      location: json['location'],
      website: json['website'],
      friendsCount: json['friends_count'] != null ? int.parse(json['friends_count'].toString()) : 0,
      postsCount: json['posts_count'] != null ? int.parse(json['posts_count'].toString()) : 0,
      relationship: json['relationship'] ?? 'none',
    );
  }
}
