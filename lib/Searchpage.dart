import 'package:flutter/material.dart';

class SearchFromPostsPage extends StatefulWidget {
  const SearchFromPostsPage({super.key});

  @override
  State<SearchFromPostsPage> createState() => _SearchFromPostsPageState();
}

class _SearchFromPostsPageState extends State<SearchFromPostsPage> {
  String? _selectedLocation;
  String? _selectedPrice;
  int _matchCount = 0;

  // 🔹 カテゴリ選択（画像 UI 用）
  final Set<String> _selectedCategoryTags = {};

  // 🔹 タグ（Chip UI 用）
  final Set<String> _selectedChipTags = {};

  // 🔹 カテゴリ画像データ
  final List<Map<String, String>> _categoryItems = [
    {"label": "イタリアン", "img": "assets/italian.png"},
    {"label": "和食", "img": "assets/japanese.png"},
    {"label": "居酒屋", "img": "assets/alcohol.png"},
    {"label": "スイーツ", "img": "assets/sweats.png"},
  ];

  // 🔹 価格帯
  final List<String> _prices = [
    "~2000円", "2000~3000円", "3000~4000円", "4000~5000円",
    "5000~6000円", "6000~7000円", "7000~8000円", "8000~9000円",
    "9000~10000円", "10000~15000円", "15000~20000円",
    "20000~30000円", "30000円以上"
  ];

  // 🔹 場所
  final List<String> _locations = ["渋谷区", "新宿区", "港区", "横浜市", "大阪市", "名古屋市"];

  // 🔹 Chip タグ（復活させる部分）
  final List<String> _tags = [
    "#一人で", "#デート", "#友達と", "#家族と", "#にぎやか", "#落ち着いている",
    "#男性多め", "#女性多め", "#個室", "#ランチ", "#ディナー"
  ];

  void _filterPosts() {
    setState(() => _matchCount = 3); // 仮データ
  }

  // 🔹 カテゴリ画像 UI
  Widget _buildPhotoSelector({
    required String title,
    required List<Map<String, String>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),

        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final label = items[i]["label"]!;
              final img = items[i]["img"]!;
              final isSelected = _selectedCategoryTags.contains(label);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected
                        ? _selectedCategoryTags.remove(label)
                        : _selectedCategoryTags.add(label);
                    _filterPosts();
                  });
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.orangeAccent
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    image: DecorationImage(
                      image: AssetImage(img),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // -----------------------------
            // 🔸 場所（Dropdown）
            // -----------------------------
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


            // -----------------------------
            // 🔸 価格帯（Dropdown）
            // -----------------------------
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

            _buildPhotoSelector(
              title: "カテゴリ",
              items: _categoryItems,
            ),
            // -----------------------------
            // 🔸 タグ選択（Chip UI ← 復活！）
            // -----------------------------
            const Text('タグを選択', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedChipTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected
                          ? _selectedChipTags.remove(tag)
                          : _selectedChipTags.add(tag);
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

            // -----------------------------
            // 🔸 検索結果
            // -----------------------------
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
