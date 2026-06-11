import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/genre_options.dart';
import 'package:foodshare/map_focus_store.dart';
import 'package:foodshare/post_attributes.dart';
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
  String? _selectedPriceFilter;
  String? _selectedCategoryFilter;
  String? _selectedTagFilter;

  final List<String> _priceFilters = const [
    "~2000円",
    "2000~3000円",
    "3000円~4000円",
    "4000~5000円",
    "5000~6000円",
    "6000~7000円",
    "7000~8000円",
    "8000~9000円",
    "9000円~10000円",
    "10000~15000円",
    "15000~20000円",
    "20000~30000円",
    "30000円以上",
  ];

  bool get _hasActiveFilters =>
      _selectedLocationFilter != null ||
      _selectedPriceFilter != null ||
      _selectedCategoryFilter != null ||
      _selectedTagFilter != null;

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
      if (followingEmail != null) 'following_email': followingEmail,
      if (_selectedLocationFilter != null) 'location': _selectedLocationFilter!,
      if (_selectedPriceFilter != null) 'price_range': _selectedPriceFilter!,
      if (_selectedCategoryFilter != null) 'category': _selectedCategoryFilter!,
      if (_selectedTagFilter != null) 'tag': _selectedTagFilter!,
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
      _selectedPriceFilter = null;
      _selectedCategoryFilter = null;
      _selectedTagFilter = null;
      _recommendedPostsFuture = _fetchLatestPosts();
      _followingPostsFuture = _fetchFollowingPosts();
    });
  }

  void _showFilterSheet() {
    final locationController = TextEditingController(
      text: _selectedLocationFilter ?? '',
    );
    String? price = _selectedPriceFilter;
    String? category = _selectedCategoryFilter;
    String? tag = _selectedTagFilter;

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
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: '場所',
                          hintText: '例: 港区、渋谷区',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '誰と',
                        style: TextStyle(
                          color: foodInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CompanionFilterSelector(
                        value: isCompanionAttribute(tag) ? tag : null,
                        onChanged: (value) {
                          setSheetState(() {
                            tag = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      FoodGenreSelector(
                        value: category,
                        recommendedGenreNames:
                            recommendedGenreNamesForCompanion(tag),
                        onChanged: (value) {
                          setSheetState(() {
                            category = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: price,
                        hint: const Text('価格帯'),
                        items: _priceFilters
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            price = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '席・喫煙',
                        style: TextStyle(
                          color: foodInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PostAttributeFilterSelector(
                        value: isCompanionAttribute(tag) ? null : tag,
                        groups: facilityAttributeGroups,
                        onChanged: (value) {
                          setSheetState(() {
                            tag = value;
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
                            _selectedPriceFilter = price;
                            _selectedCategoryFilter = category;
                            _selectedTagFilter = tag;
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
            postsFuture: _recommendedPostsFuture,
            onRefresh: _refreshRecommended,
            emptyText: 'まだ投稿がありません',
            hasActiveFilters: _hasActiveFilters,
            onClearFilters: _clearFilters,
          ),
          _PostFeed(
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
    required this.postsFuture,
    required this.onRefresh,
    required this.emptyText,
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

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
                return InstaPostCard(post: posts[index]);
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
            trailing: post.latitude == null || post.longitude == null
                ? null
                : IconButton.filledTonal(
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
