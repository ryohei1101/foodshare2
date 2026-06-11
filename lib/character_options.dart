import 'package:flutter/material.dart';

enum CharacterKind { man, woman }

class CharacterOption {
  const CharacterOption({
    required this.kind,
    required this.colorName,
    required this.color,
    required this.assetPath,
    required this.profileImagePath,
  });

  final CharacterKind kind;
  final String colorName;
  final Color color;
  final String assetPath;
  final String profileImagePath;
}

const manCharacters = [
  CharacterOption(
    kind: CharacterKind.man,
    colorName: 'Black',
    color: Color(0xFF2A2725),
    assetPath: 'assets/characters/man/man_black.png',
    profileImagePath: 'uploads/characters/man/man_black.png',
  ),
  CharacterOption(
    kind: CharacterKind.man,
    colorName: 'Brown',
    color: Color(0xFF8A5B3D),
    assetPath: 'assets/characters/man/man_brown.png',
    profileImagePath: 'uploads/characters/man/man_brown.png',
  ),
  CharacterOption(
    kind: CharacterKind.man,
    colorName: 'Green',
    color: Color(0xFF3F8E5A),
    assetPath: 'assets/characters/man/man_green.png',
    profileImagePath: 'uploads/characters/man/man_green.png',
  ),
  CharacterOption(
    kind: CharacterKind.man,
    colorName: 'Navy',
    color: Color(0xFF253B73),
    assetPath: 'assets/characters/man/man_navy.png',
    profileImagePath: 'uploads/characters/man/man_navy.png',
  ),
  CharacterOption(
    kind: CharacterKind.man,
    colorName: 'Red',
    color: Color(0xFFC84436),
    assetPath: 'assets/characters/man/man_red.png',
    profileImagePath: 'uploads/characters/man/man_red.png',
  ),
  CharacterOption(
    kind: CharacterKind.man,
    colorName: 'Yellow',
    color: Color(0xFFE9BE38),
    assetPath: 'assets/characters/man/man_yellow.png',
    profileImagePath: 'uploads/characters/man/man_yellow.png',
  ),
];

const womanCharacters = [
  CharacterOption(
    kind: CharacterKind.woman,
    colorName: 'Red',
    color: Color(0xFFD9504C),
    assetPath: 'assets/characters/woman/woman_red.png',
    profileImagePath: 'uploads/characters/woman/woman_red.png',
  ),
  CharacterOption(
    kind: CharacterKind.woman,
    colorName: 'Light Blue',
    color: Color(0xFF8FC9E8),
    assetPath: 'assets/characters/woman/woman_lightblue.png',
    profileImagePath: 'uploads/characters/woman/woman_lightblue.png',
  ),
  CharacterOption(
    kind: CharacterKind.woman,
    colorName: 'Light Green',
    color: Color(0xFF9BCB86),
    assetPath: 'assets/characters/woman/woman_lightgreen.png',
    profileImagePath: 'uploads/characters/woman/woman_lightgreen.png',
  ),
  CharacterOption(
    kind: CharacterKind.woman,
    colorName: 'Orange',
    color: Color(0xFFE98B42),
    assetPath: 'assets/characters/woman/woman_orange.png',
    profileImagePath: 'uploads/characters/woman/woman_orange.png',
  ),
  CharacterOption(
    kind: CharacterKind.woman,
    colorName: 'Pink',
    color: Color(0xFFE88BA8),
    assetPath: 'assets/characters/woman/woman_pink.png',
    profileImagePath: 'uploads/characters/woman/woman_pink.png',
  ),
  CharacterOption(
    kind: CharacterKind.woman,
    colorName: 'Yellow',
    color: Color(0xFFE9C84D),
    assetPath: 'assets/characters/woman/woman_yellow.png',
    profileImagePath: 'uploads/characters/woman/woman_yellow.png',
  ),
];

List<CharacterOption> charactersForKind(CharacterKind kind) {
  return switch (kind) {
    CharacterKind.man => manCharacters,
    CharacterKind.woman => womanCharacters,
  };
}

CharacterOption defaultCharacterForKind(CharacterKind kind) {
  return charactersForKind(kind).first;
}

String characterKindLabel(CharacterKind kind) {
  return switch (kind) {
    CharacterKind.man => 'Man',
    CharacterKind.woman => 'Woman',
  };
}
