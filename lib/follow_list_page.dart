import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/user_model.dart';
import 'package:foodshare/user_profile_page.dart';
import 'package:http/http.dart' as http;

class FollowListPage extends StatefulWidget {
  const FollowListPage({
    super.key,
    required this.email,
    required this.currentEmail,
    required this.listType,
  });

  final String email;
  final String currentEmail;
  final String listType;

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  late Future<List<FoodUser>> _usersFuture;

  String get _title => widget.listType == 'followers' ? 'フォロワー' : 'フォロー中';

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<FoodUser>> _fetchUsers() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/follow-list'
      '?email=${Uri.encodeComponent(widget.email)}'
      '&list_type=${widget.listType}'
      '&viewer_email=${Uri.encodeComponent(widget.currentEmail)}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: FutureBuilder<List<FoodUser>>(
        future: _usersFuture,
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
            return Center(
              child: Text(
                widget.listType == 'followers'
                    ? 'まだフォロワーはいません'
                    : 'まだフォローしていません',
                style: const TextStyle(color: foodMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user.profileImageUrl),
                ),
                title: Text(
                  user.username.isEmpty ? user.email : user.username,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(user.email),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(
                        targetUser: user,
                        currentEmail: widget.currentEmail,
                      ),
                    ),
                  ).then((_) {
                    setState(() {
                      _usersFuture = _fetchUsers();
                    });
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
