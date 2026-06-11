import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';

class FoodGenre {
  const FoodGenre({required this.name, required this.children});

  final String name;
  final List<String> children;
}

const foodGenres = [
  FoodGenre(
    name: '居酒屋',
    children: ['九州料理', 'もつ鍋', '焼き鳥', '海鮮', '串揚げ', '餃子', '個室居酒屋', '創作居酒屋'],
  ),
  FoodGenre(
    name: '和食',
    children: ['寿司', '天ぷら', 'そば', 'うどん', 'しゃぶしゃぶ', 'すき焼き', '鍋', 'おでん'],
  ),
  FoodGenre(name: '焼肉・ホルモン', children: ['焼肉', 'ホルモン', 'ジンギスカン', '牛タン', '韓国焼肉']),
  FoodGenre(
    name: 'イタリアン・フレンチ',
    children: ['イタリアン', 'パスタ', 'ピザ', 'フレンチ', 'ビストロ', 'バル'],
  ),
  FoodGenre(
    name: '洋食',
    children: ['ハンバーグ', 'オムライス', 'ステーキ', 'カレー', 'グリル', '洋食屋'],
  ),
  FoodGenre(
    name: '中華',
    children: ['四川料理', '広東料理', '台湾料理', '点心', '餃子', '担々麺', '町中華'],
  ),
  FoodGenre(name: '韓国料理', children: ['サムギョプサル', 'チゲ', '韓国鍋', 'チキン']),
  FoodGenre(
    name: 'アジア・エスニック',
    children: ['タイ料理', 'ベトナム料理', 'インド料理', 'ネパール料理', 'シンガポール料理'],
  ),
  FoodGenre(name: 'ラーメン', children: ['醤油', '味噌', '豚骨', '塩', 'つけ麺', '油そば']),
  FoodGenre(
    name: 'カフェ・スイーツ',
    children: ['カフェ', '喫茶店', 'ケーキ', 'パンケーキ', '和菓子', 'ベーカリー', 'スイーツ'],
  ),
  FoodGenre(
    name: 'バー・ダイニングバー',
    children: ['バー', 'ワインバー', 'カクテル', 'クラフトビール', 'ダイニングバー', 'ドリンク'],
  ),
  FoodGenre(name: 'お好み焼き・もんじゃ', children: ['お好み焼き', 'もんじゃ', 'たこ焼き']),
  FoodGenre(name: '創作料理', children: ['創作和食', '創作洋食', '多国籍料理']),
  FoodGenre(name: '各国料理', children: ['スペイン料理', 'メキシコ料理', 'ハワイ料理', '地中海料理']),
  FoodGenre(name: 'その他', children: ['ファミレス', 'ビュッフェ', 'テイクアウト', 'その他']),
];

String genreValue(String parent, [String? child]) {
  if (child == null || child.isEmpty) {
    return parent;
  }
  return '$parent / $child';
}

FoodGenre? genreForValue(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parentName = value.split(' / ').first;
  for (final genre in foodGenres) {
    if (genre.name == parentName) {
      return genre;
    }
  }

  return null;
}

String? genreChildForValue(String? value) {
  if (value == null || !value.contains(' / ')) {
    return null;
  }
  return value.split(' / ').skip(1).join(' / ');
}

class FoodGenreSelector extends StatelessWidget {
  const FoodGenreSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.recommendedGenreNames = const [],
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> recommendedGenreNames;

  @override
  Widget build(BuildContext context) {
    final selectedGenre = genreForValue(value);
    final selectedChild = genreChildForValue(value);
    final isChildView = selectedGenre != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: isChildView
          ? _GenreChipGroup(
              key: ValueKey(selectedGenre.name),
              children: [
                _GenreChipData(
                  label: '大分類へ戻る',
                  icon: Icons.arrow_back,
                  onTap: () => onChanged(null),
                ),
                _GenreChipData(
                  label: '${selectedGenre.name} 全般',
                  selected: selectedChild == null,
                  onTap: () => onChanged(selectedGenre.name),
                ),
                ...selectedGenre.children.map(
                  (child) => _GenreChipData(
                    label: child,
                    selected: selectedChild == child,
                    onTap: () =>
                        onChanged(genreValue(selectedGenre.name, child)),
                  ),
                ),
              ],
            )
          : _GenreParentGroups(
              key: const ValueKey('parents'),
              recommendedGenreNames: recommendedGenreNames,
              onChanged: onChanged,
            ),
    );
  }
}

List<String> recommendedGenreNamesForCompanion(String? companion) {
  return switch (companion) {
    'デート' => ['イタリアン・フレンチ', 'バー・ダイニングバー', '和食', 'カフェ・スイーツ'],
    '友達' => ['居酒屋', '焼肉・ホルモン', '韓国料理', 'お好み焼き・もんじゃ'],
    '一人' => ['ラーメン', 'カフェ・スイーツ', '和食', '洋食'],
    '宴会' => ['居酒屋', '焼肉・ホルモン', '中華', '韓国料理'],
    '接待' => ['和食', 'イタリアン・フレンチ', '焼肉・ホルモン', 'バー・ダイニングバー'],
    '家族' => ['和食', '洋食', '焼肉・ホルモン', 'カフェ・スイーツ'],
    '合コン' => ['居酒屋', 'イタリアン・フレンチ', 'バー・ダイニングバー', '韓国料理'],
    _ => const [],
  };
}

class _GenreParentGroups extends StatelessWidget {
  const _GenreParentGroups({
    super.key,
    required this.recommendedGenreNames,
    required this.onChanged,
  });

  final List<String> recommendedGenreNames;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final recommended = foodGenres
        .where((genre) => recommendedGenreNames.contains(genre.name))
        .toList();
    final others = foodGenres
        .where((genre) => !recommendedGenreNames.contains(genre.name))
        .toList();

    if (recommended.isEmpty) {
      return _GenreChipGroup(
        children: foodGenres.map((genre) => _parentChip(genre)).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'おすすめ',
          style: TextStyle(
            color: foodMuted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _GenreChipGroup(
          children: recommended.map((genre) => _parentChip(genre)).toList(),
        ),
        const SizedBox(height: 14),
        const Text(
          'それ以外',
          style: TextStyle(
            color: foodMuted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _GenreChipGroup(
          children: others.map((genre) => _parentChip(genre)).toList(),
        ),
      ],
    );
  }

  _GenreChipData _parentChip(FoodGenre genre) {
    return _GenreChipData(
      label: genre.name,
      onTap: () => onChanged(genre.name),
    );
  }
}

class _GenreChipData {
  const _GenreChipData({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;
}

class _GenreChipGroup extends StatelessWidget {
  const _GenreChipGroup({super.key, required this.children});

  final List<_GenreChipData> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children.map((item) {
        final selected = item.selected;

        return ChoiceChip(
          avatar: item.icon == null
              ? null
              : Icon(
                  item.icon,
                  size: 18,
                  color: selected ? Colors.white : foodPrimary,
                ),
          label: Text(item.label),
          selected: selected,
          onSelected: (_) => item.onTap(),
          selectedColor: foodPrimary,
          backgroundColor: const Color(0xFFFFEFE3),
          labelStyle: TextStyle(
            color: selected ? Colors.white : foodPrimary,
            fontWeight: FontWeight.w800,
          ),
          side: const BorderSide(color: foodPrimary),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
