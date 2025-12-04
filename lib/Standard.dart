import 'package:flutter/material.dart';
import "package:foodshare/homepage.dart";
import "package:foodshare/Postpage.dart";
import "package:foodshare/profilePage.dart";
import "package:foodshare/SearchPage.dart";
import "package:foodshare/ActivityPage.dart";
import "package:foodshare/Searchpage2.dart";
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ★ 全ページで AppBar 非表示
      appBar: null,

      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.map),
              label: '地図'),
          NavigationDestination(icon: Icon(Icons.schedule), label: '最新'),
          NavigationDestination(
              icon: Icon(Icons.add),
              selectedIcon: Icon(Icons.add),
              label: '投稿'),
          NavigationDestination(icon: Icon(Icons.search), label: '検索'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'プロフィール'),
        ],
      ),
    );
  }
}
