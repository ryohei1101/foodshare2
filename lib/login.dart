import 'package:flutter/material.dart';
import 'package:foodshare/Standard.dart';
import 'package:foodshare/New_or_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();

  String selectedDomain = "gmail.com";

  final List<String> domains = [
    "gmail.com",
    "yahoo.co.jp",
    "icloud.com",
    "outlook.com"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea( // ⭐おすすめ
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
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

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: userController,
                      decoration: const InputDecoration(
                        labelText: "メールアドレス",
                        hintText: "example",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),
                  const Text("@"),
                  const SizedBox(width: 8),

                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedDomain,
                      items: domains.map((domain) {
                        return DropdownMenuItem(
                          value: domain,
                          child: Text(domain),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDomain = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextField(
                decoration: const InputDecoration(
                  labelText: "パスワード",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),

              const SizedBox(height: 20),

              // ⭐ 次へ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String email =
                        "${userController.text}@$selectedDomain";

                    print("メール: $email");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InstaHome(),
                      ),
                    );
                  },
                  child: const Text("ログインする"),
                ),
              ),

              const SizedBox(height: 10),

              // ⭐ 戻るボタン追加
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