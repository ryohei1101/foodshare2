import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/post_model.dart';
import 'package:http/http.dart' as http;

class TimeLinePage extends StatefulWidget {
  const TimeLinePage({super.key});

  @override
  State<TimeLinePage> createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<FoodPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _postsFuture = _fetchLatestPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<FoodPost>> _fetchLatestPosts() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/posts?limit=50'),
    );

    if (response.statusCode != 200) {
      throw Exception('投稿を取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final posts = data['posts'] as List<dynamic>? ?? [];

    return posts
        .map((post) => FoodPost.fromJson(post as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _postsFuture = _fetchLatestPosts();
    });
    await _postsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timeline"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: foodPrimary,
          unselectedLabelColor: foodMuted,
          indicatorColor: foodPrimary,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          tabs: const [
            Tab(text: "おすすめ"),
            Tab(text: "フォロー中"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostFeed(postsFuture: _postsFuture, onRefresh: _refresh),
          _PostFeed(postsFuture: _postsFuture, onRefresh: _refresh),
        ],
      ),
    );
  }
}

class _PostFeed extends StatelessWidget {
  const _PostFeed({required this.postsFuture, required this.onRefresh});

  final Future<List<FoodPost>> postsFuture;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodPost>>(
      future: postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _FeedMessage(
            icon: Icons.error_outline,
            text: snapshot.error.toString(),
            onRefresh: onRefresh,
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _FeedMessage(
            icon: Icons.restaurant_outlined,
            text: 'まだ投稿がありません',
            onRefresh: onRefresh,
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, index) {
              return InstaPostCard(post: posts[index]);
            },
          ),
        );
      },
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.text,
    required this.onRefresh,
  });

  final IconData icon;
  final String text;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Icon(icon, color: foodMuted, size: 42),
          const SizedBox(height: 12),
          Center(
            child: Text(text, style: const TextStyle(color: foodMuted)),
          ),
        ],
      ),
    );
  }
}

class InstaPostCard extends StatelessWidget {
  const InstaPostCard({super.key, required this.post});

  final FoodPost post;

  @override
  Widget build(BuildContext context) {
    return FoodCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEFE3),
              child: Icon(Icons.person, color: foodPrimary),
            ),
            title: Text(
              post.username,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(post.location),
          ),
          AspectRatio(
            aspectRatio: 1.05,
            child: Image.network(
              post.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Center(child: Icon(Icons.broken_image_outlined));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(post.category)),
                    Chip(label: Text(post.priceRange)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.comment,
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
