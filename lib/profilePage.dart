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
    "~2000円",
    "2000~3000円",
    "3000~4000円",
    "4000~5000円",
    "5000~6000円",
    "6000~7000円",
    "7000~8000円",
    "8000~9000円",
    "9000円~10000円",
    "10000~15000円",
    "15000~20000円",
    "20000~30000円",
    "30000円以上"
  ];
  final List<String> _tags = [
    "#一人で",
    "#デート",
    "#友達と",
    "#家族と",
    "#にぎやか",
    "#落ち着いている",
    "#男性多め",
    "#女性多め",
    "#個室",
    "#ランチ",
    "#ディナー"
  ];
  final List<String> _locations = ["渋谷区", "新宿区", "港区", "横浜市", "大阪市", "名古屋市"];
  int _matchCount = 0;

  void _filterPosts() {
    setState(() => _matchCount = 3); // 仮データ
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

  // ============================
  // 🔥 投稿から検索ビュー（内部）
  // ============================
  Widget _buildSearchView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------ 場所 ------------------
          const Text('場所を選択', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLocation,
            hint: const Text('場所を選択してください'),
            items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (val) {
              setState(() => _selectedLocation = val);
              _filterPosts();
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // ------------------ カテゴリ ------------------
          const Text('カテゴリを選択', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            hint: const Text('カテゴリを選択してください'),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) {
              setState(() => _selectedCategory = val);
              _filterPosts();
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // ------------------ 価格帯 ------------------
          const Text('価格帯を選択', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPrice,
            hint: const Text('価格帯を選択してください'),
            items: _prices.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              setState(() => _selectedPrice = val);
              _filterPosts();
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // ------------------ タグ ------------------
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
                    isSelected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
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
    );
  }

  // ============================
  // 🔥 メイン UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Profile'),
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
                      Image.asset('assets/QR_code.png', width: 300, height: 300),
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

      // ============================
      // 🔥 本体
      // ============================
      body: Column(
        children: [
          // ------------------------------
          // ① ヘッダー（削除）
          // ------------------------------
          const SizedBox(height: 10),

          // ------------------------------
          // ② プロフィール画像
          // ------------------------------
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: ClipOval(
                child: Image.asset("assets/qualify.png", fit: BoxFit.cover),
              ),
            ),
          ),


          const SizedBox(height: 20),

          // ------------------------------
          // ③ 情報カード
          // ------------------------------
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Age :", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("24 years"),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("sample@1209"),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _smallInfoCard("イタリアン"),
                    _smallInfoCard("高級志向"),
                    _smallInfoCard("ディナー"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ------------------------------
          // ④ タブバー
          // ------------------------------
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.orangeAccent,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "投稿"),
              Tab(text: "投稿から検索"),
            ],
          ),

          // ------------------------------
          // ⑤ タブビュー
          // ------------------------------
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
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

                _buildSearchView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================
// 🔧 補助ウィジェット（クラス外）
// ============================

Widget _roundIcon(IconData icon) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey.shade200,
    ),
    child: Icon(icon, size: 20),
  );
}

Widget _smallInfoCard(String title) {
  return Container(
    width: 90,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(1, 2),
        )
      ],
    ),
    child: Center(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}

