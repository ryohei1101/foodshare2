import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/User_name_register.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/character_options.dart';

class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({
    super.key,
    required this.email,
    required this.password,
    required this.gender,
    required this.birthday,
  });

  final String email;
  final String password;
  final String gender;
  final DateTime birthday;

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  CharacterOption? _selectedCharacter;
  int _debugTapCount = 0;
  DateTime? _lastDebugTapAt;

  void _goNext(CharacterOption character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserNamePage(
          email: widget.email,
          password: widget.password,
          gender: widget.gender,
          birthday: widget.birthday,
          profileImage: character.profileImagePath,
        ),
      ),
    );
  }

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
    _goNext(_selectedCharacter ?? defaultCharacter);
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
            'キャラクター選択',
            style: TextStyle(
              color: foodInk,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'プロフィールに表示する自分だけのキャラクターを選んでください。',
          style: TextStyle(color: foodMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: characterOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final character = characterOptions[index];
            final isSelected = _selectedCharacter == character;

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _selectedCharacter = character;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? foodPrimary : foodLine,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x22E97132),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(character.assetPath, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: _selectedCharacter == null
              ? null
              : () => _goNext(_selectedCharacter!),
          child: const Text('次へ'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('戻る'),
        ),
      ],
    );
  }
}
