import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> postImages = [
    'assets/qualify.png',
    'assets/pasta.png',
  ];

  // === 検索関連 ===
  String? _selectedCategory;
  String? _selectedPrice;
  String? _selectedLocation;
  final Set<String> _selectedTags = {};

  final List<String> _categories = ['和食', '洋食', '中華', 'スイーツ', 'ドリンク', 'その他'];
  final List<String> _prices = [
    "~2000円", "2000~3000円", "3000~4000円", "4000~5000円",
    "5000~6000円", "6000~7000円", "7000~8000円", "8000~9000円",
    "9000円~10000円", "10000~15000円", "15000~20000円",
    "20000~30000円", "30000円以上"
  ];
  final List<String> _tags = [
    "#一人で", "#デート", "#友達と", "#家族と",
    "#にぎやか", "#落ち着いている", "#男性多め", "#女性多め", "#個室",
    "#ランチ", "#ディナー"
  ];
  final List<String> _locations = ["渋谷区", "新宿区", "港区", "横浜市", "大阪市", "名古屋市"];
  int _matchCount = 0;

  void _filterPosts() {
    // 仮：検索結果をダミーで3件ヒットとする
    setState(() => _matchCount = 3);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('@Ryohei_1111'),
        // centerTitle: true を消去してデフォルト左寄せ
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  contentPadding: const EdgeInsets.all(12),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/QR_code.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      const Text('このQRコードを共有できます'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),


      body: Column(
        children: [
          // === フォロワー／フォロー数 ===
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _Metric(label: '投稿', value: '42'),
                _Metric(label: 'フォロワー', value: '1.2k'),
                _Metric(label: 'フォロー中', value: '180'),
              ],
            ),
          ),

          // === タブバー ===
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.orangeAccent,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "投稿"),
                Tab(text: "投稿から検索"),
              ],
            ),
          ),

          // === 下部内容切り替え ===
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 投稿グリッド
                GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: postImages.length,
                  itemBuilder: (context, i) {
                    return Image.asset(postImages[i], fit: BoxFit.cover);
                  },
                ),

                // 投稿から検索ビュー
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 場所
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

                      // カテゴリ
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

                      // 価格帯
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

                      // タグ選択
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
                                if (isSelected) {
                                  _selectedTags.remove(tag);
                                } else {
                                  _selectedTags.add(tag);
                                }
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
                              backgroundColor: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.orangeAccent.withOpacity(0.2),
                              side: const BorderSide(color: Colors.orangeAccent),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 40),

                      // 件数
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
