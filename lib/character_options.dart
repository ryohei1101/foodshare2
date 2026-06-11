class CharacterOption {
  const CharacterOption({
    required this.label,
    required this.assetPath,
    required this.profileImagePath,
  });

  final String label;
  final String assetPath;
  final String profileImagePath;
}

const characterOptions = [
  CharacterOption(
    label: 'Woman Light Blue',
    assetPath: 'assets/characters/woman/woman_lightblue.png',
    profileImagePath: 'uploads/characters/woman/woman_lightblue.png',
  ),
  CharacterOption(
    label: 'Woman Light Green',
    assetPath: 'assets/characters/woman/woman_lightgreen.png',
    profileImagePath: 'uploads/characters/woman/woman_lightgreen.png',
  ),
  CharacterOption(
    label: 'Woman Orange',
    assetPath: 'assets/characters/woman/woman_orange.png',
    profileImagePath: 'uploads/characters/woman/woman_orange.png',
  ),
  CharacterOption(
    label: 'Woman Pink',
    assetPath: 'assets/characters/woman/woman_pink.png',
    profileImagePath: 'uploads/characters/woman/woman_pink.png',
  ),
  CharacterOption(
    label: 'Woman Red',
    assetPath: 'assets/characters/woman/woman_red.png',
    profileImagePath: 'uploads/characters/woman/woman_red.png',
  ),
  CharacterOption(
    label: 'Woman Yellow',
    assetPath: 'assets/characters/woman/woman_yellow.png',
    profileImagePath: 'uploads/characters/woman/woman_yellow.png',
  ),
  CharacterOption(
    label: 'Man Black',
    assetPath: 'assets/characters/man/man_black.png',
    profileImagePath: 'uploads/characters/man/man_black.png',
  ),
  CharacterOption(
    label: 'Man Brown',
    assetPath: 'assets/characters/man/man_brown.png',
    profileImagePath: 'uploads/characters/man/man_brown.png',
  ),
  CharacterOption(
    label: 'Man Green',
    assetPath: 'assets/characters/man/man_green.png',
    profileImagePath: 'uploads/characters/man/man_green.png',
  ),
  CharacterOption(
    label: 'Man Navy',
    assetPath: 'assets/characters/man/man_navy.png',
    profileImagePath: 'uploads/characters/man/man_navy.png',
  ),
  CharacterOption(
    label: 'Man Red',
    assetPath: 'assets/characters/man/man_red.png',
    profileImagePath: 'uploads/characters/man/man_red.png',
  ),
  CharacterOption(
    label: 'Man Yellow',
    assetPath: 'assets/characters/man/man_yellow.png',
    profileImagePath: 'uploads/characters/man/man_yellow.png',
  ),
];

final defaultCharacter = characterOptions.first;
