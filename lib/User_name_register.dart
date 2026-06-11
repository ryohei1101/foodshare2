import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/Standard.dart';
import 'package:foodshare/app_ui.dart';
import 'package:http/http.dart' as http;

class UserNamePage extends StatefulWidget {
  final String email;
  final String password;
  final String gender;
  final DateTime birthday;
  final String profileImage;

  const UserNamePage({
    super.key,
    required this.email,
    required this.password,
    required this.gender,
    required this.birthday,
    required this.profileImage,
  });

  @override
  State<UserNamePage> createState() => _UserNamePageState();
}

class _UserNamePageState extends State<UserNamePage> {
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  int _debugTapCount = 0;
  DateTime? _lastDebugTapAt;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<bool> registerUser({
    required String email,
    required String password,
    required String username,
    required String gender,
    required DateTime birthday,
    required String profileImage,
  }) async {
    final url = Uri.parse("http://10.0.2.2:8000/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "username": username,
          "gender": gender,
          "birthday": birthday.toIso8601String().split("T")[0],
          "profile_image": profileImage,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<void> completeRegistration() async {
    final username = nameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ユーザー名を入力してください")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    final isSuccess = await registerUser(
      email: widget.email,
      password: widget.password,
      username: username,
      gender: widget.gender,
      birthday: widget.birthday,
      profileImage: widget.profileImage,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (isSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InstaHome(
            email: widget.email,
            birthday: widget.birthday.toIso8601String().split("T")[0],
            profileImage: widget.profileImage,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("登録に失敗しました")));
    }
  }

  void _handleDebugCompleteTap() {
    if (!kDebugMode) {
      return;
    }

    final now = DateTime.now();
    if (_lastDebugTapAt == null ||
        now.difference(_lastDebugTapAt!) > const Duration(seconds: 2)) {
      _debugTapCount = 0;
    }

    _lastDebugTapAt = now;
    _debugTapCount += 1;

    if (_debugTapCount < 2) {
      return;
    }

    _debugTapCount = 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            InstaHome(email: 'dummy5@test.com', birthday: '', profileImage: ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FoodScaffold(
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleDebugCompleteTap,
          child: const Text(
            "ユーザー名",
            style: TextStyle(
              color: foodInk,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Food Shareで表示する名前を入力してください。",
          style: TextStyle(color: foodMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        FoodCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "ユーザー名",
                  hintText: "例: foodlover123",
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoading ? null : completeRegistration,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(isLoading ? "登録中" : "完了"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("戻る"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
