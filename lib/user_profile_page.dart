import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/Timeline.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/follow_list_page.dart';
import 'package:foodshare/genre_options.dart';
import 'package:foodshare/post_attributes.dart';
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
  late Future<int> _groupCountFuture;
  late Future<List<FoodPost>> _postsFuture;
  bool _isUpdatingFollow = false;
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

  bool get _hasActivePostFilters =>
      _selectedLocationFilter != null ||
      _selectedPriceFilter != null ||
      _selectedCategoryFilter != null ||
      _selectedTagFilter != null;

  @override
  void initState() {
    super.initState();
    _user = widget.targetUser;
    _statsFuture = _fetchFollowStats();
    _groupCountFuture = _fetchGroupCount();
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
    final uri = Uri.http('10.0.2.2:8000', '/posts', {
      'user_email': _user.email,
      'limit': '100',
      if (_selectedLocationFilter != null) 'location': _selectedLocationFilter!,
      if (_selectedPriceFilter != null) 'price_range': _selectedPriceFilter!,
      if (_selectedCategoryFilter != null) 'category': _selectedCategoryFilter!,
      if (_selectedTagFilter != null) 'tag': _selectedTagFilter!,
    });
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

  Future<int> _fetchGroupCount() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/group-stats?email=${Uri.encodeComponent(_user.email)}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return 0;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return data['groups_count'] as int? ?? 0;
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

  Future<void> _reportUser() async {
    final reason = await _showReasonDialog('ユーザーを通報');
    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/reports'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reporter_email': widget.currentEmail,
        'target_type': 'user',
        'target_id': _user.email,
        'target_owner_email': _user.email,
        'reason': reason.trim(),
      }),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.statusCode == 200 ? '通報しました' : '通報に失敗しました'),
      ),
    );
  }

  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ブロックしますか？'),
        content: Text(
          '${_user.username.isEmpty ? _user.email : _user.username}をブロックします。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ブロック'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/block'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'blocker_email': widget.currentEmail,
        'blocked_email': _user.email,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ブロックしました')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ブロックに失敗しました')));
    }
  }

  Future<String?> _showReasonDialog(String title) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _statsFuture = _fetchFollowStats();
      _groupCountFuture = _fetchGroupCount();
      _postsFuture = _fetchPosts();
    });
    await Future.wait([_statsFuture, _groupCountFuture, _postsFuture]);
  }

  void _clearPostFilters() {
    if (!_hasActivePostFilters) {
      return;
    }

    setState(() {
      _selectedLocationFilter = null;
      _selectedPriceFilter = null;
      _selectedCategoryFilter = null;
      _selectedTagFilter = null;
      _postsFuture = _fetchPosts();
    });
  }

  void _showPostFilterSheet() {
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
                        '投稿を絞り込む',
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
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            final location = locationController.text.trim();
                            _selectedLocationFilter = location.isEmpty
                                ? null
                                : location;
                            _selectedPriceFilter = price;
                            _selectedCategoryFilter = category;
                            _selectedTagFilter = tag;
                            _postsFuture = _fetchPosts();
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('条件で表示'),
                      ),
                      if (_hasActivePostFilters) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearPostFilters();
                          },
                          child: const Text('絞り込みを解除'),
                        ),
                      ],
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
    final isFilteringPosts = _hasActivePostFilters;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          if (_user.email != widget.currentEmail)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  _reportUser();
                } else if (value == 'block') {
                  _blockUser();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'report', child: Text('通報')),
                PopupMenuItem(value: 'block', child: Text('ブロック')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: NotificationListener<OverscrollNotification>(
          onNotification: (notification) {
            if (_hasActivePostFilters &&
                notification.metrics.pixels <= 0 &&
                notification.overscroll < -18) {
              _clearPostFilters();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              _user.profileImageUrl,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  width: 96,
                                  height: 96,
                                  color: foodLine,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.person,
                                    color: foodMuted,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: foodInk,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: foodMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FutureBuilder<Map<String, int>>(
                                  future: _statsFuture,
                                  builder: (context, statsSnapshot) {
                                    return FutureBuilder<int>(
                                      future: _groupCountFuture,
                                      builder: (context, groupSnapshot) {
                                        final stats =
                                            statsSnapshot.data ??
                                            const {
                                              'followers_count': 0,
                                              'following_count': 0,
                                            };

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _ProfileStat(
                                              label: 'フォロワー',
                                              count:
                                                  stats['followers_count'] ?? 0,
                                              onTap: () =>
                                                  _openFollowList('followers'),
                                            ),
                                            _ProfileStat(
                                              label: 'フォロー',
                                              count:
                                                  stats['following_count'] ?? 0,
                                              onTap: () =>
                                                  _openFollowList('following'),
                                            ),
                                            _ProfileStat(
                                              label: 'グループ',
                                              count: groupSnapshot.data ?? 0,
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_user.email != widget.currentEmail) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: _user.isFollowing
                              ? OutlinedButton(
                                  onPressed: _isUpdatingFollow
                                      ? null
                                      : _toggleFollow,
                                  child: Text(
                                    _isUpdatingFollow ? '更新中' : 'フォロー中',
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _isUpdatingFollow
                                      ? null
                                      : _toggleFollow,
                                  child: Text(
                                    _isUpdatingFollow ? '更新中' : 'フォローする',
                                  ),
                                ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E9ED),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: isFilteringPosts
                                      ? Colors.transparent
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isFilteringPosts
                                      ? null
                                      : Border.all(
                                          color: const Color(0xFFBFC0C4),
                                        ),
                                  boxShadow: isFilteringPosts
                                      ? null
                                      : const [
                                          BoxShadow(
                                            color: Color(0x1A000000),
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.grid_on, size: 15),
                                    const SizedBox(width: 8),
                                    Text(
                                      '投稿',
                                      style: TextStyle(
                                        color: isFilteringPosts
                                            ? foodInk
                                            : foodPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: isFilteringPosts
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isFilteringPosts
                                      ? Border.all(
                                          color: const Color(0xFFBFC0C4),
                                        )
                                      : null,
                                  boxShadow: isFilteringPosts
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x1A000000),
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _showPostFilterSheet,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isFilteringPosts
                                            ? Icons.manage_search
                                            : Icons.search,
                                        color: isFilteringPosts
                                            ? foodPrimary
                                            : foodInk,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '絞り込み',
                                        style: TextStyle(
                                          color: isFilteringPosts
                                              ? foodPrimary
                                              : foodInk,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_hasActivePostFilters)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '上に引っ張ると条件を解除できます',
                            style: TextStyle(color: foodMuted, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _UserPostsGrid(
                postsFuture: _postsFuture,
                currentEmail: widget.currentEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.count, this.onTap});

  final String label;
  final int count;
  final VoidCallback? onTap;

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
  const _UserPostsGrid({required this.postsFuture, required this.currentEmail});

  final Future<List<FoodPost>> postsFuture;
  final String currentEmail;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodPost>>(
      future: postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: foodMuted),
              textAlign: TextAlign.center,
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const SliverFillRemaining(
            child: Text('まだ投稿がありません', style: TextStyle(color: foodMuted)),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = posts[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserPostDetailPage(
                        posts: posts,
                        initialIndex: index,
                        currentEmail: currentEmail,
                      ),
                    ),
                  );
                },
                child: Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const ColoredBox(
                      color: Color(0xFFFFEFE3),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: foodMuted,
                      ),
                    );
                  },
                ),
              );
            }, childCount: posts.length),
          ),
        );
      },
    );
  }
}

class UserPostDetailPage extends StatefulWidget {
  const UserPostDetailPage({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.currentEmail,
  });

  final List<FoodPost> posts;
  final int initialIndex;
  final String currentEmail;

  @override
  State<UserPostDetailPage> createState() => _UserPostDetailPageState();
}

class _UserPostDetailPageState extends State<UserPostDetailPage> {
  late final List<GlobalKey> _postKeys;

  @override
  void initState() {
    super.initState();
    _postKeys = List.generate(widget.posts.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.initialIndex >= _postKeys.length) {
        return;
      }

      final context = _postKeys[widget.initialIndex].currentContext;
      if (context == null) {
        return;
      }

      Scrollable.ensureVisible(
        context,
        duration: Duration.zero,
        alignment: 0.04,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('投稿')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        itemCount: widget.posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return KeyedSubtree(
            key: _postKeys[index],
            child: InstaPostCard(
              post: widget.posts[index],
              currentEmail: widget.currentEmail,
            ),
          );
        },
      ),
    );
  }
}
