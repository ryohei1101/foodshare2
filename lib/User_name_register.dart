import 'package:flutter/material.dart';
import 'package:foodshare/Standard.dart';

class UserNamePage extends StatefulWidget {
  const UserNamePage({super.key});

  @override
  State<UserNamePage> createState() => _UserNamePageState();
}

class _UserNamePageState extends State<UserNamePage> {
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          // ⭐ ここに Column を追加しました！
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
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

              const SizedBox(height: 82.5),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "ユーザー名",
                  hintText: "例: foodlover123",
                  border: OutlineInputBorder(),
                ),
              ),

              // ⭐ Spacerを削除し、固定の余白を入れる
              // QuestionPageのDatePicker(150) + 選択結果テキスト(20) + 余白などを考慮
              const SizedBox(height: 82.5),

              // ⭐ 完了ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 完了処理
                    String username = nameController.text;
                     Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InstaHome(), // Standard.dartの内容に合わせて修正してください
                      ),
                    );
                  },
                  child: const Text("完了"),
                ),
              ),

              const SizedBox(height: 10),

              // 戻るボタン
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("戻る"),
                ),
              ),

              const SizedBox(height: 40),

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

              // 最後に Spacer を入れることで、全体を上に詰める（QuestionPageと同じ構造）
              const Spacer(),
            ],
          ), // ⭐ Columnの閉じカッコ
        ),
      ),
    );
  }
}