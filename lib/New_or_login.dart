import 'package:flutter/material.dart';
import 'package:foodshare/SignUpPage.dart';
import 'package:foodshare/login.dart';

class NewOrLoginPage extends StatelessWidget {
  const NewOrLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ⭐ 左上
          Positioned(
            top: 0,
            left: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/way1.png',
                width: 180,
              ),
            ),
          ),

          // ⭐ 右上
          Positioned(
            top: 120,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/way2.png',
                width: 180,
              ),
            ),
          ),

          // ⭐ メインUI（先に書く）
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Food Shareへようこそ",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: const Text("新規作成"),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text("ログイン"),
                  ),
                ),
              ],
            ),
          ),

          // ⭐ 一番最後に書く → 最前面
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/way3.png',
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      )
    );
  }
}