import 'package:flutter/material.dart';

class Post {
  final String username;
  final String caption;
  final String imageUrl;
  final String avatarUrl;
  final int likeCount;
  final String timeAgo;
  final String shopname;
  final String category;
  final String spot;

  Post({
    required this.username,
    required this.caption,
    required this.imageUrl,
    required this.avatarUrl,
    required this.likeCount,
    required this.timeAgo,
    required this.shopname,
    required this.category,
    required this.spot,
  });
}

// ===== テストデータ =====
//多分ここ，avatarUrlを前回投稿とかに修正する
final demoPosts = [
  Post(
    username: 'test_user',
    caption: 'これはテスト投稿です',
    imageUrl: 'assets/stake.png',  // ← ローカル画像
    avatarUrl: 'assets/stake.png', // ← アイコン用
    likeCount: 120,
    timeAgo: '3時間前',
    shopname:"Starbucks",
    category:"italian",
    spot:"渋谷区",

  ),
  Post(
    username: 'another_user',
    caption: 'もう1枚のテスト投稿です',
    imageUrl: 'assets/sushi.png',
    avatarUrl: 'assets/sushi.png',
    likeCount: 85,
    timeAgo: '5時間前',
    shopname:"Starbucks",
    category:"cafe",
    spot:"渋谷区",
  ),
];
