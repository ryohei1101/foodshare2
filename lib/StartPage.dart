import 'package:flutter/material.dart';
import "package:foodshare/Standard.dart";

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // 5秒後にHomePageへ遷移
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>const InstaHome()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orangeAccent,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ❤️ 背景ハート
            Icon(
              Icons.favorite,
              color: Colors.redAccent.withOpacity(0.4), // 半透明にして柔らかく
              size: 400, // ハートの大きさ（大きめ）
            ),

            // 📝 テキスト部分
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Food Share',
                  style: TextStyle(
                    fontSize: 54,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "What's your favorite food???",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
