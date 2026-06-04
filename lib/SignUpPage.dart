import 'package:flutter/material.dart';
import 'package:foodshare/New_or_login.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/asking_page1.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FoodScaffold(
      children: [
        const SizedBox(height: 12),
        const Text(
          "アカウント作成",
          style: TextStyle(
            color: foodInk,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "まずはログインに使う情報を登録します。",
          style: TextStyle(color: foodMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        FoodCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "メールアドレス",
                  hintText: "example@gmail.com",
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "パスワード",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QuestionPage(email: email, password: password),
                    ),
                  );
                },
                child: const Text("次へ"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const NewOrLoginPage()),
                  );
                },
                child: const Text("戻る"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          "最近行った店を投稿して、好みの合う人を見つけよう",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foodInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset('assets/way1.png', height: 230, fit: BoxFit.cover),
        ),
      ],
    );
  }
}
