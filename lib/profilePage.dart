import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foodshare/Timeline.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/follow_list_page.dart';
import 'package:foodshare/genre_options.dart';
import 'package:foodshare/group_list_page.dart';
import 'package:foodshare/post_attributes.dart';
import 'package:foodshare/post_model.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final String birthday;
  final String profileImage;

  const ProfilePage({
    super.key,
    required this.email,
    required this.birthday,
    required this.profileImage,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  File? selectedImage;
  late Future<List<FoodPost>> _myPostsFuture;
  late Future<Map<String, int>> _followStatsFuture;
  late Future<int> _groupCountFuture;
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
    WidgetsBinding.instance.addObserver(this);
    _myPostsFuture = _fetchMyPosts();
    _followStatsFuture = _fetchFollowStats();
    _groupCountFuture = _fetchGroupCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadProfileCounts();
    }
  }

  Future<void> uploadImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("http://10.0.2.2:8000/upload-profile-image"),
    );

    request.fields['email'] = widget.email;
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      debugPrint("upload success");
    } else {
      debugPrint("upload failed");
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      return;
    }

    final pickedFile = File(image.path);

    setState(() {
      selectedImage = pickedFile;
    });

    await uploadImage(pickedFile);
  }

  Future<List<FoodPost>> _fetchMyPosts() async {
    final uri = Uri.http('10.0.2.2:8000', '/posts', {
      'user_email': widget.email,
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

  Future<Map<String, int>> _fetchFollowStats() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/follow-stats?email=${Uri.encodeComponent(widget.email)}',
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

  Future<int> _fetchGroupCount() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/group-stats?email=${Uri.encodeComponent(widget.email)}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return 0;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return data['groups_count'] as int? ?? 0;
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _myPostsFuture = _fetchMyPosts();
      _followStatsFuture = _fetchFollowStats();
      _groupCountFuture = _fetchGroupCount();
    });
    await Future.wait([_myPostsFuture, _followStatsFuture, _groupCountFuture]);
  }

  void _reloadProfileCounts() {
    if (!mounted) {
      return;
    }

    setState(() {
      _followStatsFuture = _fetchFollowStats();
      _groupCountFuture = _fetchGroupCount();
    });
  }

  void _openFollowList(String listType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowListPage(
          email: widget.email,
          currentEmail: widget.email,
          listType: listType,
        ),
      ),
    ).then((_) {
      setState(() {
        _followStatsFuture = _fetchFollowStats();
      });
    });
  }

  void _openGroupList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupListPage(email: widget.email),
      ),
    ).then((_) {
      setState(() {
        _groupCountFuture = _fetchGroupCount();
      });
    });
  }

  void _reloadPosts() {
    setState(() {
      _myPostsFuture = _fetchMyPosts();
    });
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
      _myPostsFuture = _fetchMyPosts();
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
                          _reloadPosts();
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('検索する'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearPostFilters();
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
    final isFilteringPosts = _hasActivePostFilters;

    return Scaffold(
      appBar: AppBar(elevation: 0, toolbarHeight: 0),
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
                          _ProfileImage(
                            imageFile: selectedImage,
                            profileImage: widget.profileImage,
                            onTap: pickImage,
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: foodInk,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FutureBuilder<Map<String, int>>(
                                  future: _followStatsFuture,
                                  builder: (context, followSnapshot) {
                                    return FutureBuilder<int>(
                                      future: _groupCountFuture,
                                      builder: (context, groupSnapshot) {
                                        final stats =
                                            followSnapshot.data ??
                                            const {
                                              'followers_count': 0,
                                              'following_count': 0,
                                            };

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _FollowStatButton(
                                              label: 'フォロワー',
                                              count:
                                                  stats['followers_count'] ?? 0,
                                              onTap: () =>
                                                  _openFollowList('followers'),
                                            ),
                                            _FollowStatButton(
                                              label: 'フォロー',
                                              count:
                                                  stats['following_count'] ?? 0,
                                              onTap: () =>
                                                  _openFollowList('following'),
                                            ),
                                            _FollowStatButton(
                                              label: 'グループ',
                                              count: groupSnapshot.data ?? 0,
                                              onTap: _openGroupList,
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
                      const SizedBox(height: 26),
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
              _MyPostsGrid(postsFuture: _myPostsFuture),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({
    required this.imageFile,
    required this.profileImage,
    required this.onTap,
  });

  final File? imageFile;
  final String profileImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileImage.isNotEmpty
        ? "http://10.0.2.2:8000/$profileImage"
        : "http://10.0.2.2:8000/uploads/cutiestreet.png";

    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE4E4E8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: imageFile != null
                  ? Image.file(imageFile!, fit: BoxFit.cover)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: foodLine,
                          alignment: Alignment.center,
                          child: const Icon(Icons.person, color: foodMuted),
                        );
                      },
                    ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: foodPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowStatButton extends StatelessWidget {
  const _FollowStatButton({
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

class _MyPostsGrid extends StatelessWidget {
  const _MyPostsGrid({required this.postsFuture});

  final Future<List<FoodPost>> postsFuture;

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
            child: Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: foodMuted),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text('まだ投稿がありません', style: TextStyle(color: foodMuted)),
            ),
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
                      builder: (_) => ProfilePostDetailPage(
                        posts: posts,
                        initialIndex: index,
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

class ProfilePostDetailPage extends StatefulWidget {
  const ProfilePostDetailPage({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  final List<FoodPost> posts;
  final int initialIndex;

  @override
  State<ProfilePostDetailPage> createState() => _ProfilePostDetailPageState();
}

class _ProfilePostDetailPageState extends State<ProfilePostDetailPage> {
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
            child: InstaPostCard(post: widget.posts[index]),
          );
        },
      ),
    );
  }
}
