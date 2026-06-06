import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:foodshare/account_search_page.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/follow_list_page.dart';
import 'package:foodshare/post_model.dart';
import 'package:foodshare/user_model.dart';
import 'package:foodshare/user_profile_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ⭐ 選択画像
  File? selectedImage;
  late Future<List<FoodPost>> _myPostsFuture;
  late Future<Map<String, int>> _followStatsFuture;
  late Future<List<FoodUser>> _usersFuture;

  // ⭐ 年齢計算
  int? calculateAge(String birthday) {
    final birth = DateTime.tryParse(birthday);

    if (birth == null) {
      return null;
    }

    final today = DateTime.now();

    int age = today.year - birth.year;

    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }

    return age;
  }

  // ⭐ 画像アップロード
  Future<void> uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',

      Uri.parse("http://10.0.2.2:8000/upload-profile-image"),
    );

    // ⭐ email送信
    request.fields['email'] = widget.email;

    // ⭐ file送信
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      debugPrint("upload success");
    } else {
      debugPrint("upload failed");
    }
  }

  // ⭐ 画像選択
  Future<void> pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File pickedFile = File(image.path);

      setState(() {
        selectedImage = pickedFile;
      });

      // ⭐ FastAPIへ送信
      await uploadImage(pickedFile);
    }
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _myPostsFuture = _fetchMyPosts();
    _followStatsFuture = _fetchFollowStats();
    _usersFuture = _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final age = calculateAge(widget.birthday);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'アカウント検索',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AccountSearchPage(currentEmail: widget.email),
                ),
              ).then((_) => _reloadFollowData());
            },
            icon: const Icon(Icons.person_search),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ⭐ プロフィール画像
                Stack(
                  children: [
                    Container(
                      width: 132,
                      height: 132,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        gradient: LinearGradient(
                          colors: [foodPrimary, const Color(0xFFFFC285)],
                        ),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(6),

                        child: ClipOval(
                          child: selectedImage != null
                              // ⭐ ローカル画像
                              ? Image.file(selectedImage!, fit: BoxFit.cover)
                              // ⭐ DB画像
                              : Image.network(
                                  widget.profileImage.isNotEmpty
                                      ? "http://10.0.2.2:8000/${widget.profileImage}"
                                      : "http://10.0.2.2:8000/uploads/cutiestreet.png",

                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),

                    // ⭐ 右下プラスボタン
                    Positioned(
                      bottom: 5,
                      right: 5,

                      child: GestureDetector(
                        onTap: pickImage,

                        child: Container(
                          width: 42,
                          height: 42,

                          decoration: BoxDecoration(
                            color: foodPrimary,

                            shape: BoxShape.circle,

                            border: Border.all(color: Colors.white, width: 3),
                          ),

                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: FutureBuilder<Map<String, int>>(
                    future: _followStatsFuture,
                    builder: (context, snapshot) {
                      final stats =
                          snapshot.data ??
                          const {'followers_count': 0, 'following_count': 0};

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

            // ⭐ 情報カード
            FoodCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        "Age :",

                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Text(age == null ? "-" : "$age years"),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        "ID:",

                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Flexible(
                        child: Text(
                          widget.email,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ⭐ タブ
            TabBar(
              controller: _tabController,

              indicatorColor: Colors.orangeAccent,

              tabs: const [
                Tab(text: "投稿"),
                Tab(text: "アカウント"),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,

                children: [
                  _MyPostsGrid(postsFuture: _myPostsFuture),

                  _UserDiscoveryList(
                    currentEmail: widget.email,
                    usersFuture: _usersFuture,
                    onFollowChanged: _reloadFollowData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<List<FoodUser>> _fetchUsers() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/users'
      '?exclude_email=${Uri.encodeComponent(widget.email)}'
      '&viewer_email=${Uri.encodeComponent(widget.email)}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('アカウントを取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final users = data['users'] as List<dynamic>? ?? [];

    return users
        .map((user) => FoodUser.fromJson(user as Map<String, dynamic>))
        .toList();
  }

  void _reloadFollowData() {
    setState(() {
      _followStatsFuture = _fetchFollowStats();
      _usersFuture = _fetchUsers();
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
    );
  }
}

class _UserDiscoveryList extends StatelessWidget {
  const _UserDiscoveryList({
    required this.currentEmail,
    required this.usersFuture,
    required this.onFollowChanged,
  });

  final String currentEmail;
  final Future<List<FoodUser>> usersFuture;
  final VoidCallback onFollowChanged;

  Future<void> _toggleFollow(FoodUser user) async {
    final endpoint = user.isFollowing ? 'unfollow' : 'follow';

    await http.post(
      Uri.parse('http://10.0.2.2:8000/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'follower_email': currentEmail,
        'following_email': user.email,
      }),
    );

    onFollowChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodUser>>(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: foodMuted),
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text('表示できるアカウントがありません', style: TextStyle(color: foodMuted)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 20),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.profileImageUrl),
              ),
              title: Text(
                user.username.isEmpty ? user.email : user.username,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(user.email),
              trailing: OutlinedButton(
                onPressed: () => _toggleFollow(user),
                child: Text(user.isFollowing ? '解除' : 'フォロー'),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfilePage(
                      targetUser: user,
                      currentEmail: currentEmail,
                    ),
                  ),
                ).then((_) => onFollowChanged());
              },
            );
          },
        );
      },
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: foodMuted),
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
          padding: const EdgeInsets.all(4),
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
