import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/User_name_register.dart';
import 'package:foodshare/app_ui.dart';

class QuestionPage extends StatefulWidget {
  final String email;
  final String password;

  const QuestionPage({super.key, required this.email, required this.password});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  DateTime selectedDate = DateTime(2000, 1, 1);
  String? selectedGender;
  int _debugTapCount = 0;
  DateTime? _lastDebugTapAt;

  void _handleDebugNextTap() {
    if (!kDebugMode) {
      return;
    }

    final now = DateTime.now();
    if (_lastDebugTapAt == null ||
        now.difference(_lastDebugTapAt!) > const Duration(seconds: 2)) {
      _debugTapCount = 0;
    }

    _lastDebugTapAt = now;
    _debugTapCount += 1;

    if (_debugTapCount < 2) {
      return;
    }

    _debugTapCount = 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserNamePage(
          email: 'dummy5@test.com',
          password: '',
          gender: selectedGender ?? 'その他',
          birthday: selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FoodScaffold(
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleDebugNextTap,
          child: const Text(
            "プロフィール設定",
            style: TextStyle(
              color: foodInk,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "おすすめを合わせるための基本情報を入力します。",
          style: TextStyle(color: foodMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        FoodCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FoodSectionTitle("生年月日"),
              const SizedBox(height: 10),
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
              const SizedBox(height: 20),
              const FoodSectionTitle("性別"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  genderButton("男性"),
                  genderButton("女性"),
                  genderButton("その他"),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
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
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("戻る"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget genderButton(String gender) {
    final isSelected = selectedGender == gender;

    return ChoiceChip(
      label: Text(gender),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedGender = gender;
        });
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : foodInk,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: foodPrimary,
      backgroundColor: Colors.white,
      side: const BorderSide(color: foodLine),
    );
  }
}
