class FoodPost {
  const FoodPost({
    required this.id,
    required this.userEmail,
    required this.imagePath,
    required this.category,
    required this.priceRange,
    required this.location,
    required this.comment,
    required this.createdAt,
    required this.username,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String userEmail;
  final String imagePath;
  final String category;
  final String priceRange;
  final String location;
  final String comment;
  final String createdAt;
  final String username;
  final double? latitude;
  final double? longitude;

  String get imageUrl => 'http://10.0.2.2:8000/$imagePath';

  factory FoodPost.fromJson(Map<String, dynamic> json) {
    return FoodPost(
      id: json['id'] as int,
      userEmail: json['user_email'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      category: json['category'] as String? ?? '',
      priceRange: json['price_range'] as String? ?? '',
      location: json['location'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      username:
          json['username'] as String? ?? json['user_email'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
