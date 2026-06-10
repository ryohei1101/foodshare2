import 'package:flutter/material.dart';

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
    this.parentHint = 'ジャンル',
    this.childHint = '細分類',
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String parentHint;
  final String childHint;

  @override
  Widget build(BuildContext context) {
    final selectedGenre = genreForValue(value);
    final selectedChild = genreChildForValue(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedGenre?.name,
          hint: Text(parentHint),
          items: foodGenres
              .map(
                (genre) => DropdownMenuItem(
                  value: genre.name,
                  child: Text(genre.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
        if (selectedGenre != null && selectedGenre.children.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedChild,
            hint: Text(childHint),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text('${selectedGenre.name}すべて'),
              ),
              ...selectedGenre.children.map(
                (child) => DropdownMenuItem(value: child, child: Text(child)),
              ),
            ],
            onChanged: (child) {
              onChanged(
                child == null || child.isEmpty
                    ? selectedGenre.name
                    : genreValue(selectedGenre.name, child),
              );
            },
          ),
        ],
      ],
    );
  }
}
