import "package:flutter/material.dart";

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("アクティビティ"),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "ここにアクティビティ内容を表示します。",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
