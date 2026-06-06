class FoodPost {
  const FoodPost({
    required this.id,
    required this.userEmail,
    required this.imagePath,
    required this.shopName,
    required this.category,
    required this.priceRange,
    required this.location,
    required this.comment,
    required this.tags,
    required this.createdAt,
    required this.username,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String userEmail;
  final String imagePath;
  final String shopName;
  final String category;
  final String priceRange;
  final String location;
  final String comment;
  final String tags;
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
      shopName: json['shop_name'] as String? ?? '店名未設定',
      category: json['category'] as String? ?? '',
      priceRange: json['price_range'] as String? ?? '',
      location: json['location'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      username:
          json['username'] as String? ?? json['user_email'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
