import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/genre_options.dart';
import 'package:foodshare/map_focus_store.dart';
import 'package:foodshare/post_model.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TimeLinePage extends StatefulWidget {
  const TimeLinePage({super.key, required this.email});

  final String email;

  @override
  State<TimeLinePage> createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<FoodPost>> _recommendedPostsFuture;
  late Future<List<FoodPost>> _followingPostsFuture;
  String? _selectedLocationFilter;
  String? _selectedCategoryFilter;

  bool get _hasActiveFilters =>
      _selectedLocationFilter != null || _selectedCategoryFilter != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recommendedPostsFuture = _fetchLatestPosts();
    _followingPostsFuture = _fetchFollowingPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Uri _postsUri({String? followingEmail}) {
    return Uri.http('10.0.2.2:8000', '/posts', {
      'limit': '50',
      'viewer_email': widget.email,
      if (followingEmail != null) 'following_email': followingEmail,
      if (_selectedLocationFilter != null) 'location': _selectedLocationFilter!,
      if (_selectedCategoryFilter != null) 'category': _selectedCategoryFilter!,
    });
  }

  Future<List<FoodPost>> _fetchLatestPosts() async {
    final response = await http.get(_postsUri());

    if (response.statusCode != 200) {
      throw Exception('投稿を取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final posts = data['posts'] as List<dynamic>? ?? [];

    return posts
        .map((post) => FoodPost.fromJson(post as Map<String, dynamic>))
        .toList();
  }

  Future<List<FoodPost>> _fetchFollowingPosts() async {
    final response = await http.get(_postsUri(followingEmail: widget.email));

    if (response.statusCode != 200) {
      throw Exception('投稿を取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final posts = data['posts'] as List<dynamic>? ?? [];

    return posts
        .map((post) => FoodPost.fromJson(post as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refreshRecommended() async {
    setState(() {
      _recommendedPostsFuture = _fetchLatestPosts();
    });
    await _recommendedPostsFuture;
  }

  Future<void> _refreshFollowing() async {
    setState(() {
      _followingPostsFuture = _fetchFollowingPosts();
    });
    await _followingPostsFuture;
  }

  void _reloadFeeds() {
    setState(() {
      _recommendedPostsFuture = _fetchLatestPosts();
      _followingPostsFuture = _fetchFollowingPosts();
    });
  }

  void _clearFilters() {
    if (!_hasActiveFilters) {
      return;
    }

    setState(() {
      _selectedLocationFilter = null;
      _selectedCategoryFilter = null;
      _recommendedPostsFuture = _fetchLatestPosts();
      _followingPostsFuture = _fetchFollowingPosts();
    });
  }

  void _showFilterSheet() {
    final locationController = TextEditingController(
      text: _selectedLocationFilter ?? '',
    );
    String? category = _selectedCategoryFilter;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '条件で探す',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '場所',
                        style: TextStyle(
                          color: foodInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          hintText: '例: 港区、渋谷区',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ジャンル',
                        style: TextStyle(
                          color: foodInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FoodGenreSelector(
                        value: category,
                        onChanged: (value) {
                          setSheetState(() {
                            category = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedLocationFilter =
                                locationController.text.trim().isEmpty
                                ? null
                                : locationController.text.trim();
                            _selectedCategoryFilter = category;
                          });
                          Navigator.pop(context);
                          _reloadFeeds();
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('検索する'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearFilters();
                        },
                        child: const Text('条件をクリア'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
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
              IconButton(
                tooltip: '条件で探す',
                onPressed: _showFilterSheet,
                icon: Icon(
                  _hasActiveFilters ? Icons.manage_search : Icons.search,
                  color: _hasActiveFilters ? foodPrimary : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostFeed(
            currentEmail: widget.email,
            postsFuture: _recommendedPostsFuture,
            onRefresh: _refreshRecommended,
            emptyText: 'まだ投稿がありません',
            hasActiveFilters: _hasActiveFilters,
            onClearFilters: _clearFilters,
          ),
          _PostFeed(
            currentEmail: widget.email,
            postsFuture: _followingPostsFuture,
            onRefresh: _refreshFollowing,
            emptyText: 'フォロー中のユーザーの投稿はまだありません',
            hasActiveFilters: _hasActiveFilters,
            onClearFilters: _clearFilters,
          ),
        ],
      ),
    );
  }
}

class _PostFeed extends StatelessWidget {
  const _PostFeed({
    required this.currentEmail,
    required this.postsFuture,
    required this.onRefresh,
    required this.emptyText,
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  final String currentEmail;
  final Future<List<FoodPost>> postsFuture;
  final Future<void> Function() onRefresh;
  final String emptyText;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

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
            hasActiveFilters: hasActiveFilters,
            onClearFilters: onClearFilters,
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _FeedMessage(
            icon: Icons.restaurant_outlined,
            text: emptyText,
            onRefresh: onRefresh,
            hasActiveFilters: hasActiveFilters,
            onClearFilters: onClearFilters,
          );
        }

        return NotificationListener<OverscrollNotification>(
          onNotification: (notification) {
            if (hasActiveFilters &&
                notification.metrics.pixels <= 0 &&
                notification.overscroll < -18) {
              onClearFilters();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, index) {
                return InstaPostCard(
                  post: posts[index],
                  currentEmail: currentEmail,
                  onChanged: onRefresh,
                );
              },
            ),
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
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  final IconData icon;
  final String text;
  final Future<void> Function() onRefresh;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        if (hasActiveFilters &&
            notification.metrics.pixels <= 0 &&
            notification.overscroll < -18) {
          onClearFilters();
        }
        return false;
      },
      child: RefreshIndicator(
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
      ),
    );
  }
}

class InstaPostCard extends StatelessWidget {
  const InstaPostCard({
    super.key,
    required this.post,
    this.currentEmail,
    this.onChanged,
  });

  final FoodPost post;
  final String? currentEmail;
  final Future<void> Function()? onChanged;

  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿を削除しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true || currentEmail == null) {
      return;
    }

    final response = await http.delete(
      Uri.parse(
        'http://10.0.2.2:8000/posts/${post.id}?user_email=${Uri.encodeComponent(currentEmail!)}',
      ),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.statusCode == 200 ? '削除しました' : '削除に失敗しました'),
      ),
    );

    if (response.statusCode == 200) {
      await onChanged?.call();
    }
  }

  Future<void> _reportPost(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿を通報'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: '理由を入力してください'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('送信'),
          ),
        ],
      ),
    );

    if (reason == null || reason.trim().isEmpty || currentEmail == null) {
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/reports'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reporter_email': currentEmail,
        'target_type': 'post',
        'target_id': post.id.toString(),
        'target_owner_email': post.userEmail,
        'reason': reason.trim(),
      }),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.statusCode == 200 ? '通報しました' : '通報に失敗しました'),
      ),
    );
  }

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (post.latitude != null && post.longitude != null)
                  IconButton.filledTonal(
                    tooltip: '地図で見る',
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () {
                      MapFocusStore.focus(
                        LatLng(post.latitude!, post.longitude!),
                        label: post.shopName,
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                if (currentEmail != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(context);
                      } else if (value == 'report') {
                        _reportPost(context);
                      }
                    },
                    itemBuilder: (context) => [
                      if (post.userEmail == currentEmail)
                        const PopupMenuItem(value: 'delete', child: Text('削除')),
                      if (post.userEmail != currentEmail)
                        const PopupMenuItem(value: 'report', child: Text('通報')),
                    ],
                  ),
              ],
            ),
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
