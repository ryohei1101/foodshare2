import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/follow_list_page.dart';
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

class _ProfilePageState extends State<ProfilePage> {
  File? selectedImage;
  late Future<List<FoodPost>> _myPostsFuture;
  late Future<Map<String, int>> _followStatsFuture;

  @override
  void initState() {
    super.initState();
    _myPostsFuture = _fetchMyPosts();
    _followStatsFuture = _fetchFollowStats();
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
    final uri = Uri.parse(
      'http://10.0.2.2:8000/posts?user_email=${Uri.encodeComponent(widget.email)}&limit=100',
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

  Future<void> _refreshProfile() async {
    setState(() {
      _myPostsFuture = _fetchMyPosts();
      _followStatsFuture = _fetchFollowStats();
    });
    await Future.wait([_myPostsFuture, _followStatsFuture]);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: Text(widget.email)),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ProfileImage(
                          imageFile: selectedImage,
                          profileImage: widget.profileImage,
                          onTap: pickImage,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: FutureBuilder<Map<String, int>>(
                            future: _followStatsFuture,
                            builder: (context, snapshot) {
                              final stats =
                                  snapshot.data ??
                                  const {
                                    'followers_count': 0,
                                    'following_count': 0,
                                  };

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _FollowStatButton(
                                    label: 'フォロワー',
                                    count: stats['followers_count'] ?? 0,
                                    onTap: () => _openFollowList('followers'),
                                  ),
                                  _FollowStatButton(
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
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: foodLine),
                  ],
                ),
              ),
            ),
            _MyPostsGrid(postsFuture: _myPostsFuture),
          ],
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
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [foodPrimary, const Color(0xFFFFC285)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
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
            }, childCount: posts.length),
          ),
        );
      },
    );
  }
}
