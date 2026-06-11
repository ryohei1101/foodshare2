import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/character_options.dart';
import 'package:http/http.dart' as http;

class CharacterProfileEditPage extends StatefulWidget {
  const CharacterProfileEditPage({
    super.key,
    required this.email,
    required this.currentProfileImage,
  });

  final String email;
  final String currentProfileImage;

  @override
  State<CharacterProfileEditPage> createState() =>
      _CharacterProfileEditPageState();
}

class _CharacterProfileEditPageState extends State<CharacterProfileEditPage> {
  CharacterKind? _selectedKind;
  CharacterOption? _selectedCharacter;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentCharacter = _findCurrentCharacter();
    if (currentCharacter != null) {
      _selectedKind = currentCharacter.kind;
      _selectedCharacter = currentCharacter;
    }
  }

  CharacterOption? _findCurrentCharacter() {
    for (final character in [...manCharacters, ...womanCharacters]) {
      if (character.profileImagePath == widget.currentProfileImage) {
        return character;
      }
    }
    return null;
  }

  void _selectKind(CharacterKind kind) {
    setState(() {
      _selectedKind = kind;
      _selectedCharacter = _initialCharacterForKind(kind);
    });
  }

  CharacterOption _initialCharacterForKind(CharacterKind kind) {
    final characters = charactersForKind(kind);
    for (final character in characters) {
      if (character.profileImagePath == widget.currentProfileImage) {
        return character;
      }
    }
    return defaultCharacterForKind(kind);
  }

  Future<void> _saveCharacter() async {
    final character = _selectedCharacter;
    if (character == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/update-profile-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'profile_image': character.profileImagePath,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final imagePath =
            data['profile_image'] as String? ?? character.profileImagePath;
        Navigator.pop(context, imagePath);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] as String? ?? '更新できませんでした')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('通信エラーが発生しました')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedKind = _selectedKind;
    final selectedCharacter = _selectedCharacter;
    final characters = selectedKind == null
        ? const <CharacterOption>[]
        : charactersForKind(selectedKind);

    return FoodScaffold(
      title: 'キャラクター変更',
      children: [
        const FoodSectionTitle('性別'),
        const SizedBox(height: 12),
        Row(
          children: [
            _KindChoiceButton(
              label: characterKindLabel(CharacterKind.man),
              character: manCharacters.first,
              isSelected: selectedKind == CharacterKind.man,
              onTap: () => _selectKind(CharacterKind.man),
            ),
            const SizedBox(width: 12),
            _KindChoiceButton(
              label: characterKindLabel(CharacterKind.woman),
              character: womanCharacters.first,
              isSelected: selectedKind == CharacterKind.woman,
              onTap: () => _selectKind(CharacterKind.woman),
            ),
          ],
        ),
        if (selectedKind != null && selectedCharacter != null) ...[
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: foodSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: foodLine),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Image.asset(
                    selectedCharacter.assetPath,
                    key: ValueKey(selectedCharacter.assetPath),
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
              final isSelected = character == selectedCharacter;
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
          ElevatedButton(
            onPressed: _isSaving ? null : _saveCharacter,
            child: Text(_isSaving ? '更新中' : '決定'),
          ),
        ],
      ],
    );
  }
}

class _KindChoiceButton extends StatelessWidget {
  const _KindChoiceButton({
    required this.label,
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final CharacterOption character;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF0E7) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? foodPrimary : foodLine),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(
                  height: 104,
                  child: Image.asset(character.assetPath, fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? foodPrimary : foodInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
