import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/user_model.dart';
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
    _usersFuture = _fetchUsers();
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
    setState(() {
      _usersFuture = _fetchUsers();
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
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント検索')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'ユーザーIDで検索',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<FoodUser>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
