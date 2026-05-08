import 'package:flutter/material.dart';
import 'package:foodshare/asking_page1.dart';
import 'package:foodshare/New_or_login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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

                      const SizedBox(height: 50),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "メールアドレス",
                          hintText: "example@gmail.com",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 30),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "パスワード",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ⭐ 修正済みボタン
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () {
                            String email = emailController.text;
                            String password = passwordController.text;

                            print("email: $email");
                            print("password: $password");

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuestionPage(
                                  email: email,
                                  password: password,
                                ),
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
                                builder: (_) => const NewOrLoginPage(),
                              ),
                            );
                          },
                          child: const Text("戻る"),
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        "１.最近行った店を投稿して、\n自分と好みの合う人を見つけよう！",
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}