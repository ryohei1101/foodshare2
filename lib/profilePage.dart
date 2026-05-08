import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final String birthday;

  const ProfilePage({
    super.key,
    required this.email,
    required this.birthday,
  });

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

  // ⭐ 年齢計算
  int calculateAge(String birthday) {
    final birth = DateTime.parse(birthday);
    final today = DateTime.now();

    int age = today.year - birth.year;

    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age;
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
    int age = calculateAge(widget.birthday);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Profile'),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // ⭐ プロフィール画像
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.blue.shade100],
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

          // ⭐ 情報カード（ここ修正）
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
                  children: [
                    const Text("Age :", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("$age years"),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.email),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ⭐ タブ
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.orangeAccent,
            tabs: const [
              Tab(text: "投稿"),
              Tab(text: "検索"),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemCount: postImages.length,
                  itemBuilder: (context, i) {
                    return Image.asset(postImages[i], fit: BoxFit.cover);
                  },
                ),

                const Center(child: Text("検索画面")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}