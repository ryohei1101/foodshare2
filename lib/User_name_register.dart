import 'package:flutter/material.dart';
import 'package:foodshare/Standard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserNamePage extends StatefulWidget {
  final String email;
  final String password;
  final String gender;
  final DateTime birthday;

  const UserNamePage({
    super.key,
    required this.email,
    required this.password,
    required this.gender,
    required this.birthday,
  });

  @override
  State<UserNamePage> createState() => _UserNamePageState();
}

class _UserNamePageState extends State<UserNamePage> {
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // register APIを呼び出して、成功したら true を返す
  Future<bool> registerUser({
    required String email,
    required String password,
    required String username,
    required String gender,
    required DateTime birthday,
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
        }),
      );

      print("status: ${response.statusCode}");
      print("body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("登録失敗: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("エラー: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "ユーザー名を入力してください",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "ユーザー名",
                        hintText: "例: foodlover123",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 500),
                    const Text(
                      "３.条件に合わせて近くの店を検索",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(
                      'assets/way3.png',
                      height: 300,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 430,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        print("完了ボタン押された");

                        final username = nameController.text.trim();

                        if (username.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ユーザー名を入力してください"),
                            ),
                          );
                          return;
                        }

                        final isSuccess = await registerUser(
                          email: widget.email,
                          password: widget.password,
                          username: username,
                          gender: widget.gender,
                          birthday: widget.birthday,
                        );

                        if (!context.mounted) return;

                        if (isSuccess) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InstaHome(
                                email: widget.email,
                                birthday: widget.birthday
                                    .toIso8601String()
                                    .split("T")[0],
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("登録に失敗しました"),
                            ),
                          );
                        }
                      },
                      child: const Text("完了"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("戻る"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}