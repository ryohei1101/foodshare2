import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/follow_list_page.dart';
import 'package:foodshare/post_model.dart';
import 'package:foodshare/user_model.dart';
import 'package:http/http.dart' as http;

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    required this.targetUser,
    required this.currentEmail,
  });

  final FoodUser targetUser;
  final String currentEmail;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late FoodUser _user;
  late Future<Map<String, int>> _statsFuture;
  late Future<List<FoodPost>> _postsFuture;
  bool _isUpdatingFollow = false;

  @override
  void initState() {
    super.initState();
    _user = widget.targetUser;
    _statsFuture = _fetchFollowStats();
    _postsFuture = _fetchPosts();
  }

  Future<Map<String, int>> _fetchFollowStats() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/follow-stats?email=${Uri.encodeComponent(_user.email)}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return {'followers_count': 0, 'following_count': 0};
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return {
      'followers_count': data['followers_count'] as int? ?? 0,
      'following_count': data['following_count'] as int? ?? 0,
    };
  }

  Future<List<FoodPost>> _fetchPosts() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/posts?user_email=${Uri.encodeComponent(_user.email)}&limit=100',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('投稿を取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final posts = data['posts'] as List<dynamic>? ?? [];

    return posts
        .map((post) => FoodPost.fromJson(post as Map<String, dynamic>))
        .toList();
  }

  Future<void> _toggleFollow() async {
    if (_user.email == widget.currentEmail || _isUpdatingFollow) {
      return;
    }

    setState(() {
      _isUpdatingFollow = true;
    });

    final endpoint = _user.isFollowing ? 'unfollow' : 'follow';
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'follower_email': widget.currentEmail,
        'following_email': _user.email,
      }),
    );

    if (!mounted) return;

    setState(() {
      _isUpdatingFollow = false;
    });

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('フォロー状態を更新できませんでした')));
      return;
    }

    setState(() {
      _user = FoodUser(
        username: _user.username,
        email: _user.email,
        profileImage: _user.profileImage,
        isFollowing: !_user.isFollowing,
      );
      _statsFuture = _fetchFollowStats();
    });
  }

  void _openFollowList(String listType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListPage(
          email: _user.email,
          currentEmail: widget.currentEmail,
          listType: listType,
        ),
      ),
    ).then((_) {
      setState(() {
        _statsFuture = _fetchFollowStats();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user.username.isEmpty ? _user.email : _user.username;

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            Row(
              children: [
                ClipOval(
                  child: Image.network(
                    _user.profileImageUrl,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 104,
                        height: 104,
                        color: foodLine,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, color: foodMuted),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: FutureBuilder<Map<String, int>>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      final stats =
                          snapshot.data ??
                          const {'followers_count': 0, 'following_count': 0};

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProfileStat(
                            label: 'フォロワー',
                            count: stats['followers_count'] ?? 0,
                            onTap: () => _openFollowList('followers'),
                          ),
                          _ProfileStat(
                            label: 'フォロー',
                            count: stats['following_count'] ?? 0,
                            onTap: () => _openFollowList('following'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                displayName,
                style: const TextStyle(
                  color: foodInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _user.email,
                style: const TextStyle(color: foodMuted),
              ),
            ),
            const SizedBox(height: 14),
            if (_user.email != widget.currentEmail)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: _user.isFollowing
                    ? OutlinedButton(
                        onPressed: _isUpdatingFollow ? null : _toggleFollow,
                        child: Text(_isUpdatingFollow ? '更新中' : 'フォロー中'),
                      )
                    : ElevatedButton(
                        onPressed: _isUpdatingFollow ? null : _toggleFollow,
                        child: Text(_isUpdatingFollow ? '更新中' : 'フォローする'),
                      ),
              ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: foodLine),
            const SizedBox(height: 8),
            Expanded(child: _UserPostsGrid(postsFuture: _postsFuture)),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: foodInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: foodMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserPostsGrid extends StatelessWidget {
  const _UserPostsGrid({required this.postsFuture});

  final Future<List<FoodPost>> postsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodPost>>(
      future: postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: foodMuted),
              textAlign: TextAlign.center,
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const Center(
            child: Text('まだ投稿がありません', style: TextStyle(color: foodMuted)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Image.network(
              posts[index].imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const ColoredBox(
                  color: Color(0xFFFFEFE3),
                  child: Icon(Icons.broken_image_outlined, color: foodMuted),
                );
              },
            );
          },
        );
      },
    );
  }
}
