import 'package:flutter/material.dart';
import 'package:foodshare/asking_page1.dart';
import 'package:foodshare/New_or_login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
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

              const SizedBox(height: 50),

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

              const SizedBox(height: 25),

              TextField(
                decoration: const InputDecoration(
                  labelText: "パスワード",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),

              // ⭐ここ追加（超重要）
              const Spacer(),

              // ⭐ボタン位置がQuestionPageと揃う
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String email =
                        "${userController.text}@$selectedDomain";

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuestionPage(),
                      ),
                    );
                  },
                  child: const Text("次へ"),
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

              const SizedBox(height: 40),

              const Text(
                "１.自分と好みの合う人を見つけよう！",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Image.asset(
                'assets/way1.png',
                height: 300,
              ),
              const Spacer(),
            ],
          )
        ),
      ),
    );
  }
}