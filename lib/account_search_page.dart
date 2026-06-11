import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/user_model.dart';
import 'package:foodshare/user_profile_page.dart';
import 'package:http/http.dart' as http;

class AccountSearchPage extends StatefulWidget {
  const AccountSearchPage({super.key, required this.currentEmail});

  final String currentEmail;

  @override
  State<AccountSearchPage> createState() => _AccountSearchPageState();
}

class _AccountSearchPageState extends State<AccountSearchPage> {
  final TextEditingController _queryController = TextEditingController();
  Future<List<FoodUser>>? _usersFuture;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_scheduleSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _queryController.removeListener(_scheduleSearch);
    _queryController.dispose();
    super.dispose();
  }

  Future<List<FoodUser>> _fetchUsers() async {
    final query = _queryController.text.trim();
    final uri = Uri.http('10.0.2.2:8000', '/users', {
      'exclude_email': widget.currentEmail,
      'viewer_email': widget.currentEmail,
      if (query.isNotEmpty) 'query': query,
    });
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

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _search);
  }

  void _search() {
    _searchDebounce?.cancel();
    final query = _queryController.text.trim();
    setState(() {
      _usersFuture = query.isEmpty ? null : _fetchUsers();
    });
  }

  Future<void> _toggleFollow(FoodUser user) async {
    final endpoint = user.isFollowing ? 'unfollow' : 'follow';

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'follower_email': widget.currentEmail,
        'following_email': user.email,
      }),
    );

    if (!mounted) return;

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('フォロー状態を更新できませんでした')));
      return;
    }

    _search();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: foodSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 54,
                child: TextField(
                  controller: _queryController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'ユーザー名で検索',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: foodLine),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: foodLine),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _usersFuture == null
                    ? const Center(
                        child: Text(
                          'ユーザー名を入力してください',
                          style: TextStyle(color: foodMuted),
                        ),
                      )
                    : FutureBuilder<List<FoodUser>>(
                        future: _usersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: foodMuted,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.error.toString(),
                                    style: const TextStyle(color: foodMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          final users = snapshot.data ?? [];

                          if (users.isEmpty) {
                            return const Center(
                              child: Text(
                                '該当するアカウントがありません',
                                style: TextStyle(color: foodMuted),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final user = users[index];

                              return _AccountSearchRow(
                                user: user,
                                onFollowPressed: () => _toggleFollow(user),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfilePage(
                                        targetUser: user,
                                        currentEmail: widget.currentEmail,
                                      ),
                                    ),
                                  ).then((_) => _search());
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSearchRow extends StatelessWidget {
  const _AccountSearchRow({
    required this.user,
    required this.onFollowPressed,
    required this.onPressed,
  });

  final FoodUser user;
  final VoidCallback onFollowPressed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final displayName = user.username.isEmpty ? user.email : user.username;

    return InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                user.profileImageUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 46,
                    height: 46,
                    color: foodLine,
                    alignment: Alignment.center,
                    child: const Icon(Icons.person, color: foodMuted),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: foodInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: foodMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 112,
              height: 38,
              child: OutlinedButton(
                onPressed: onFollowPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: FittedBox(child: Text(user.isFollowing ? '解除' : 'フォロー')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
