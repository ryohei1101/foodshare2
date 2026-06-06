class FoodUser {
  const FoodUser({
    required this.username,
    required this.email,
    required this.profileImage,
    required this.isFollowing,
  });

  final String username;
  final String email;
  final String profileImage;
  final bool isFollowing;

  String get profileImageUrl => profileImage.isEmpty
      ? 'http://10.0.2.2:8000/uploads/cutiestreet.png'
      : 'http://10.0.2.2:8000/$profileImage';

  factory FoodUser.fromJson(Map<String, dynamic> json) {
    return FoodUser(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImage: json['profile_image'] as String? ?? '',
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }
}
