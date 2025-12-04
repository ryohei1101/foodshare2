import 'package:flutter/material.dart';

class SearchFromPostsPage extends StatefulWidget {
  const SearchFromPostsPage({super.key});

  @override
  State<SearchFromPostsPage> createState() => _SearchFromPostsPageState();
}

class _SearchFromPostsPageState extends State<SearchFromPostsPage> {
  String? _selectedCategory;
  String? _selectedPrice;
  String? _selectedLocation;
  final Set<String> _selectedTags = {};
  int _matchCount = 0;

  final List<String> _categories = ['和食', '洋食', '中華', 'スイーツ', 'ドリンク', 'その他'];
  final List<String> _prices = [
    "~2000円", "2000~3000円", "3000~4000円", "4000~5000円",
    "5000~6000円", "6000~7000円", "7000~8000円", "8000~9000円",
    "9000円~10000円", "10000~15000円", "15000~20000円",
    "20000~30000円", "30000円以上"
  ];
  final List<String> _locations = ["渋谷区", "新宿区", "港区", "横浜市", "大阪市", "名古屋市"];
  final List<String> _tags = [
    "#一人で", "#デート", "#友達と", "#家族と", "#にぎやか", "#落ち着いている",
    "#男性多め", "#女性多め", "#個室", "#ランチ", "#ディナー"
  ];

  void _filterPosts() {
    setState(() => _matchCount = 3); // 仮データ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("検索"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 場所選択 ---
            const Text('場所を選択', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              hint: const Text('場所を選択してください'),
              items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (val) {
                _selectedLocation = val;
                _filterPosts();
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // --- カテゴリ ---
            const Text('カテゴリを選択', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('カテゴリを選択してください'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                _selectedCategory = val;
                _filterPosts();
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // --- 価格帯 ---
            const Text('価格帯を選択', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPrice,
              hint: const Text('価格帯を選択してください'),
              items: _prices.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) {
                _selectedPrice = val;
                _filterPosts();
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // --- タグ ---
            const Text('タグを選択', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected
                          ? _selectedTags.remove(tag)
                          : _selectedTags.add(tag);
                      _filterPosts();
                    });
                  },
                  child: Chip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor:
                    isSelected ? Colors.orangeAccent : Colors.orangeAccent.withOpacity(0.2),
                    side: const BorderSide(color: Colors.orangeAccent),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            Center(
              child: Text(
                "該当件数：$_matchCount 件",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
