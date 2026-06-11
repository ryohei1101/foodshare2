import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/New_or_login.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/character_profile_edit_page.dart';
import 'package:foodshare/legal_pages.dart';
import 'package:http/http.dart' as http;

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
    required this.email,
    required this.currentProfileImage,
    required this.onProfileImageChanged,
  });

  final String email;
  final String currentProfileImage;
  final ValueChanged<String> onProfileImageChanged;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _passwordController = TextEditingController();
  late String _currentProfileImage;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentProfileImage = widget.currentProfileImage;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('パスワードを入力してください')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退会しますか？'),
        content: const Text('アカウント、投稿、フォローなどの関連データが削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退会する'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/delete-account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'password': password}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NewOrLoginPage()),
          (_) => false,
        );
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] as String? ?? '退会に失敗しました')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('通信エラーが発生しました')));
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _openCharacterEditor() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterProfileEditPage(
          email: widget.email,
          currentProfileImage: _currentProfileImage,
        ),
      ),
    );

    if (!mounted || imagePath == null || imagePath.isEmpty) {
      return;
    }

    setState(() {
      _currentProfileImage = imagePath;
    });
    widget.onProfileImageChanged(imagePath);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('プロフィール画像を更新しました')));
  }

  @override
  Widget build(BuildContext context) {
    return FoodScaffold(
      title: 'アカウント設定',
      children: [
        FoodCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.image_outlined, color: foodPrimary),
            title: const Text(
              'プロフィール画像を変更',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('画像はプロフィール画面に表示されます'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openCharacterEditor,
          ),
        ),
        const SizedBox(height: 18),
        FoodCard(
          child: Column(
            children: [
              _LegalListTile(title: '利用規約', type: LegalDocumentType.terms),
              _LegalListTile(
                title: 'プライバシーポリシー',
                type: LegalDocumentType.privacy,
              ),
              _LegalListTile(
                title: '位置情報の取り扱い',
                type: LegalDocumentType.location,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FoodCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FoodSectionTitle('退会'),
              const SizedBox(height: 8),
              const Text(
                '退会するとアカウントに紐づくデータが削除されます。',
                style: TextStyle(color: foodMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'パスワード'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isDeleting ? null : _deleteAccount,
                icon: const Icon(Icons.delete_outline),
                label: Text(_isDeleting ? '処理中' : '退会する'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalListTile extends StatelessWidget {
  const _LegalListTile({required this.title, required this.type});

  final String title;
  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LegalDocumentPage(type: type)),
        );
      },
    );
  }
}
