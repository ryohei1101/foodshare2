class FoodGroup {
  const FoodGroup({
    required this.id,
    required this.name,
    required this.ownerEmail,
    required this.createdAt,
    required this.memberCount,
  });

  final int id;
  final String name;
  final String ownerEmail;
  final String createdAt;
  final int memberCount;

  factory FoodGroup.fromJson(Map<String, dynamic> json) {
    return FoodGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      ownerEmail: json['owner_email'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      memberCount: json['member_count'] as int? ?? 0,
    );
  }
}
