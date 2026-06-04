import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timeline"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: foodPrimary,
          unselectedLabelColor: foodMuted,
          indicatorColor: foodPrimary,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          tabs: const [
            Tab(text: "おすすめ"),
            Tab(text: "フォロー中"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_InstaLikeFeed(), _InstaLikeFeed()],
      ),
    );
  }
}

class _InstaLikeFeed extends StatelessWidget {
  const _InstaLikeFeed();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: 10,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final images = [
          'assets/pasta.png',
          'assets/sushi.png',
          'assets/stake.png',
        ];
        return InstaPostCard(
          userName: "User $i",
          userIcon: Icons.person,
          imagePath: images[i % images.length],
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
    return FoodCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFEFE3),
              child: Icon(userIcon, color: foodPrimary),
            ),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text("おすすめの投稿"),
          ),
          AspectRatio(
            aspectRatio: 1.05,
            child: Image.asset(
              imagePath,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Text(
              comment,
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
