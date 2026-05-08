import 'package:flutter/material.dart';
import 'package:foodshare/Standard.dart';
import 'package:foodshare/New_or_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = "";

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "メールアドレスまたはパスワードが違います";
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("status: ${response.statusCode}");
      print("body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          errorMessage = "";
        });

        // ⭐ 修正ポイント
        String emailFromDB = data["email"];
        String birthday = data["birthday"] ?? "";
        String userId = data["uuid"]; // ←ここ変更

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InstaHome(
              email: emailFromDB,
              birthday: birthday,
            ),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          errorMessage = data["detail"] ?? "ログインに失敗しました";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "通信エラーが発生しました";
      });
      print("エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "登録情報を入力",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "メールアドレス",
                  hintText: "example@gmail.com",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: "パスワード",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),

              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  child: const Text("ログインする"),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewOrLoginPage(),
                      ),
                    );
                  },
                  child: const Text("戻る"),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}