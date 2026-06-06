import 'package:flutter/material.dart';
import "package:foodshare/account_search_page.dart";
import "package:foodshare/map.dart";
import "package:foodshare/profilePage.dart";
import "package:foodshare/Timeline.dart";

class InstaHome extends StatefulWidget {
  final String email;
  final String birthday;
  final String profileImage;

  const InstaHome({
    super.key,
    required this.email,
    required this.birthday,
    required this.profileImage,
  });

  @override
  State<InstaHome> createState() => _InstaHomeState();
}

class _InstaHomeState extends State<InstaHome> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    OSMMapPage(email: widget.email),

    TimeLinePage(email: widget.email),

    AccountSearchPage(currentEmail: widget.email),

    ProfilePage(
      email: widget.email,
      birthday: widget.birthday,
      profileImage: widget.profileImage,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final pageIndex = _currentIndex < pages.length ? _currentIndex : 0;

    return Scaffold(
      appBar: null,

      body: pages[pageIndex],

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFEFE3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

        selectedIndex: pageIndex,

        onDestinationSelected: (i) => setState(() {
          _currentIndex = i;
        }),

        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.map),
            label: '地図',
          ),

          const NavigationDestination(icon: Icon(Icons.schedule), label: '最新'),

          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
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
