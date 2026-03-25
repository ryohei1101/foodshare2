import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:foodshare/User_name_register.dart'; // ⭐追加

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  DateTime selectedDate = DateTime(2000, 1, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // タイトル
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "生年月日を入力",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 日付ピッカー
              SizedBox(
                height: 150,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  dateOrder: DatePickerDateOrder.ymd,
                  initialDateTime: selectedDate,
                  minimumDate: DateTime(1900, 1, 1),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      selectedDate = newDate;
                    });
                  },
                ),
              ),

const Spacer(),

              // 選択結果
              Text(
                "選択: ${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日",
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              // ⭐ 次へボタン（ここが修正ポイント）
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    print("生年月日: $selectedDate");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserNamePage(),
                      ),
                    );
                  },
                  child: const Text("次へ"),
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
                "２.次に行く店の相談から待ち合わせまで",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),
              Image.asset(
                'assets/way2.png',
                height:300,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}