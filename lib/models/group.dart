class Group {
  final int id;
  final String name;
  final String? description;
  final String privacy;
  final String? coverUrl;
  final int membersCount;
  final String? memberStatus;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.privacy,
    this.coverUrl,
    required this.membersCount,
    this.memberStatus,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] is int ? json['id'] : int.parse((json['id'] ?? 0).toString()),
      name: json['name'] ?? 'Group',
      description: json['description'],
      privacy: json['privacy'] ?? 'public',
      coverUrl: json['cover_url'],
      membersCount: json['members_count'] != null ? int.parse(json['members_count'].toString()) : 0,
      memberStatus: json['member_status'],
    );
  }
}
