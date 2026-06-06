import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/group_model.dart';
import 'package:foodshare/user_model.dart';
import 'package:http/http.dart' as http;

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key, required this.email});

  final String email;

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  late Future<List<FoodGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _fetchGroups();
  }

  Future<List<FoodGroup>> _fetchGroups() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/groups?email=${Uri.encodeComponent(widget.email)}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('グループを取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final groups = data['groups'] as List<dynamic>? ?? [];

    return groups
        .map((group) => FoodGroup.fromJson(group as Map<String, dynamic>))
        .toList();
  }

  void _reloadGroups() {
    setState(() {
      _groupsFuture = _fetchGroups();
    });
  }

  Future<void> _openCreateGroupPage() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateGroupPage(email: widget.email)),
    );

    if (created == true) {
      _reloadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ'),
        actions: [
          IconButton(
            tooltip: 'グループ作成',
            onPressed: _openCreateGroupPage,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<FoodGroup>>(
        future: _groupsFuture,
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

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const Center(
              child: Text(
                'まだ所属しているグループがありません',
                style: TextStyle(color: foodMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final group = groups[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEFE3),
                  child: Icon(Icons.groups_2_outlined, color: foodPrimary),
                ),
                title: Text(
                  group.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text('${group.memberCount}人のメンバー'),
              );
            },
          );
        },
      ),
    );
  }
}

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key, required this.email});

  final String email;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedEmails = {};
  late Future<List<FoodUser>> _followingFuture;
  bool _isNameStep = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _followingFuture = _fetchFollowing();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<List<FoodUser>> _fetchFollowing() async {
    final uri = Uri.parse(
      'http://10.0.2.2:8000/follow-list'
      '?email=${Uri.encodeComponent(widget.email)}'
      '&list_type=following'
      '&viewer_email=${Uri.encodeComponent(widget.email)}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('フォロー中のアカウントを取得できませんでした');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final users = data['users'] as List<dynamic>? ?? [];

    return users
        .map((user) => FoodUser.fromJson(user as Map<String, dynamic>))
        .toList();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('グループ名を入力してください')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'owner_email': widget.email,
        'name': name,
        'member_emails': _selectedEmails.toList(),
      }),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('グループを作成できませんでした')));
      return;
    }

    Navigator.pop(context, true);
  }

  void _goNext() {
    if (_selectedEmails.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('メンバーを選択してください')));
      return;
    }

    setState(() {
      _isNameStep = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNameStep ? 'グループ名' : 'メンバー選択'),
        leading: _isNameStep
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isNameStep = false;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: _isNameStep ? _buildNameStep() : _buildMemberStep(),
    );
  }

  Widget _buildMemberStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                '${_selectedEmails.length}人選択中',
                style: const TextStyle(
                  color: foodMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton(onPressed: _goNext, child: const Text('次へ')),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<FoodUser>>(
            future: _followingFuture,
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
                  child: Text(
                    'フォロー中のアカウントがありません',
                    style: TextStyle(color: foodMuted),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelected = _selectedEmails.contains(user.email);

                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isSelected,
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedEmails.remove(user.email);
                        } else {
                          _selectedEmails.add(user.email);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundImage: NetworkImage(user.profileImageUrl),
                    ),
                    title: Text(
                      user.username.isEmpty ? user.email : user.username,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(user.email),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'グループ名',
                hintText: '例: 週末ランチ部',
                prefixIcon: Icon(Icons.groups_2_outlined),
              ),
              onSubmitted: (_) => _createGroup(),
            ),
            const SizedBox(height: 12),
            Text(
              '自分を含めて${_selectedEmails.length + 1}人のグループを作成します',
              style: const TextStyle(color: foodMuted),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _createGroup,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSubmitting ? '作成中' : 'グループを作成'),
            ),
          ],
        ),
      ),
    );
  }
}
