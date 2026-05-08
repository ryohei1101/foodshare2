import 'package:flutter/material.dart';
import "package:foodshare/map.dart";
import "package:foodshare/Postpage.dart";
import "package:foodshare/profilePage.dart";
import "package:foodshare/Timeline.dart";
import "package:foodshare/Searchpage.dart";

class InstaHome extends StatefulWidget {
  final String email;
  final String birthday;

  const InstaHome({
    super.key,
    required this.email,
    required this.birthday,
  });

  @override
  State<InstaHome> createState() => _InstaHomeState();
}

class _InstaHomeState extends State<InstaHome> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      OSMMapPage(),
      TimeLinePage(),
      PostPage(),
      SearchFromPostsPage(),
      ProfilePage(
        email: widget.email,
        birthday: widget.birthday
      ),
    ];
  }

  // ★ 投稿ボタン
  Widget _postIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
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
        color: Colors.white,
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