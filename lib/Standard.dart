import 'package:flutter/material.dart';
import "package:foodshare/map.dart";
import "package:foodshare/Postpage.dart";
import "package:foodshare/profilePage.dart";
import "package:foodshare/Timeline.dart";
import "package:foodshare/Searchpage.dart";

class InstaHome extends StatefulWidget {
  const InstaHome({super.key});

  @override
  State<InstaHome> createState() => _InstaHomeState();
}

class _InstaHomeState extends State<InstaHome> {
  int _currentIndex = 0;

  final _pages = [
    OSMMapPage(),
    TimeLinePage(),
    PostPage(),
    SearchFromPostsPage(),
    ProfilePage(),
  ];

  // ★ 投稿ボタン：常に押した後の色で表示
  Widget _postIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.blueAccent, // ★ 押す前も押した後もこの色
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        size: 30,
        color: Colors.white, // ★ 白アイコンで統一
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() {
          _currentIndex = i;
        }),

        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.map),
            label: '地図',
          ),
          const NavigationDestination(
            icon: Icon(Icons.schedule),
            label: '最新',
          ),

          // ★ 投稿ボタン（常に同じ色）
          NavigationDestination(
            icon: _postIcon(),
            selectedIcon: _postIcon(),
            label: '投稿',
          ),

          const NavigationDestination(
            icon: Icon(Icons.search),
            label: '検索',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}
