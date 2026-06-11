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
  int _debugTapCount = 0;
  DateTime? _lastDebugTapAt;

  void _openColorPage(CharacterKind kind) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterColorPage(
          email: widget.email,
          password: widget.password,
          gender: widget.gender,
          birthday: widget.birthday,
          kind: kind,
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
    _openColorPage(CharacterKind.woman);
  }

  @override
  Widget build(BuildContext context) {
    final choices = [
      (kind: CharacterKind.man, character: manCharacters.first),
      (kind: CharacterKind.woman, character: womanCharacters.first),
    ];

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
          'プロフィールに表示するキャラクターを選んでください。',
          style: TextStyle(color: foodMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        Row(
          children: choices.map((choice) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _CharacterKindCard(
                  label: characterKindLabel(choice.kind),
                  character: choice.character,
                  onTap: () => _openColorPage(choice.kind),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('戻る'),
        ),
      ],
    );
  }
}

class CharacterColorPage extends StatefulWidget {
  const CharacterColorPage({
    super.key,
    required this.email,
    required this.password,
    required this.gender,
    required this.birthday,
    required this.kind,
  });

  final String email;
  final String password;
  final String gender;
  final DateTime birthday;
  final CharacterKind kind;

  @override
  State<CharacterColorPage> createState() => _CharacterColorPageState();
}

class _CharacterColorPageState extends State<CharacterColorPage> {
  late CharacterOption _selectedCharacter;
  int _debugTapCount = 0;
  DateTime? _lastDebugTapAt;

  @override
  void initState() {
    super.initState();
    _selectedCharacter = defaultCharacterForKind(widget.kind);
  }

  void _goNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserNamePage(
          email: widget.email,
          password: widget.password,
          gender: widget.gender,
          birthday: widget.birthday,
          profileImage: _selectedCharacter.profileImagePath,
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
    _goNext();
  }

  @override
  Widget build(BuildContext context) {
    final characters = charactersForKind(widget.kind);

    return FoodScaffold(
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleDebugNextTap,
          child: Text(
            '${characterKindLabel(widget.kind)} の色',
            style: const TextStyle(
              color: foodInk,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '色を選ぶとキャラクター画像が切り替わります。',
          style: TextStyle(color: foodMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: foodLine),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10241812),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Image.asset(
                  _selectedCharacter.assetPath,
                  key: ValueKey(_selectedCharacter.assetPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: characters.map((character) {
            final isSelected = character == _selectedCharacter;

            return Tooltip(
              message: character.colorName,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  setState(() {
                    _selectedCharacter = character;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: character.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? foodInk : Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 26),
        ElevatedButton(onPressed: _goNext, child: const Text('決定')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('戻る'),
        ),
      ],
    );
  }
}

class _CharacterKindCard extends StatelessWidget {
  const _CharacterKindCard({
    required this.label,
    required this.character,
    required this.onTap,
  });

  final String label;
  final CharacterOption character;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: foodLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10241812),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(character.assetPath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: foodInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
