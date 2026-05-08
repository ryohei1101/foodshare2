import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:foodshare/User_name_register.dart';

class QuestionPage extends StatefulWidget {
  final String email;
  final String password;

  const QuestionPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  DateTime selectedDate = DateTime(2000, 1, 1);
  String? selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                          "生年月日を入力",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        height: 80,
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

                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "性別を入力",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          genderButton("男性"),
                          genderButton("女性"),
                          genderButton("その他"),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ⭐ 修正ポイント
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: selectedGender == null
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserNamePage(
                                  email: widget.email,
                                  password: widget.password,
                                  gender: selectedGender!,
                                  birthday: selectedDate,
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
                          onPressed: () => Navigator.pop(context),
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

  Widget genderButton(String gender) {
    final isSelected = selectedGender == gender;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          selectedGender = gender;
        });
      },
      child: Text(gender),
    );
  }
}