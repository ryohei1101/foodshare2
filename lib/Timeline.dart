import 'package:flutter/material.dart';

class TimeLinePage extends StatefulWidget {
  const TimeLinePage({super.key});

  @override
  State<TimeLinePage> createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timeline"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "おすすめ"),
            Tab(text: "フォロー中"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _InstaLikeFeed(),
          _InstaLikeFeed(), // フォロー中も同じUIにしているが、後でデータ切替可能
        ],
      ),
    );
  }
}

class _InstaLikeFeed extends StatelessWidget {
  const _InstaLikeFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, i) {
        return InstaPostCard(
          userName: "User $i",
          userIcon: Icons.person,
          imagePath: "assets/pasta.png", // ★ あなたの assets 画像を使える
          comment: "これは投稿 $i です。美味しかった！ #foodshare",
        );
      },
    );
  }
}

class InstaPostCard extends StatelessWidget {
  final String userName;
  final IconData userIcon;
  final String imagePath;
  final String comment;

  const InstaPostCard({
    super.key,
    required this.userName,
    required this.userIcon,
    required this.imagePath,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 投稿者行
          ListTile(
            leading: CircleAvatar(
              child: Icon(userIcon),
            ),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // 写真部分
          AspectRatio(
            aspectRatio: 1, // インスタのように正方形
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // コメント
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              comment,
              style: const TextStyle(fontSize: 14),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
