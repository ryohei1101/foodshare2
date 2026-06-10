import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import "package:foodshare/account_search_page.dart";
import "package:foodshare/dm_page.dart";
import "package:foodshare/map.dart";
import "package:foodshare/map_focus_store.dart";
import "package:foodshare/profilePage.dart";
import "package:foodshare/Timeline.dart";
import 'package:http/http.dart' as http;

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
  int _unreadDmCount = 0;
  Timer? _unreadTimer;

  List<Widget> get _pages => [
    OSMMapPage(email: widget.email),

    TimeLinePage(email: widget.email),

    DmPage(currentEmail: widget.email, onUnreadChanged: _fetchUnreadDmCount),

    AccountSearchPage(currentEmail: widget.email),

    ProfilePage(
      email: widget.email,
      birthday: widget.birthday,
      profileImage: widget.profileImage,
    ),
  ];

  @override
  void initState() {
    super.initState();
    MapFocusStore.request.addListener(_handleMapFocusRequest);
    _fetchUnreadDmCount();
    _unreadTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _fetchUnreadDmCount(),
    );
  }

  @override
  void dispose() {
    MapFocusStore.request.removeListener(_handleMapFocusRequest);
    _unreadTimer?.cancel();
    super.dispose();
  }

  void _handleMapFocusRequest() {
    if (!mounted || MapFocusStore.request.value == null) {
      return;
    }

    setState(() {
      _currentIndex = 0;
    });
  }

  Future<void> _fetchUnreadDmCount() async {
    try {
      final uri = Uri.http('10.0.2.2:8000', '/dm/unread-count', {
        'email': widget.email,
      });
      final response = await http.get(uri);

      if (!mounted || response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      setState(() {
        _unreadDmCount = data['unread_count'] as int? ?? 0;
      });
    } catch (_) {}
  }

  Widget _messageIcon(IconData icon) {
    if (_unreadDmCount <= 0) {
      return Icon(icon);
    }

    return Badge.count(
      count: _unreadDmCount,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      child: Icon(icon),
    );
  }

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

        onDestinationSelected: (i) {
          setState(() {
            _currentIndex = i;
          });
          _fetchUnreadDmCount();
        },

        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '地図',
          ),

          const NavigationDestination(icon: Icon(Icons.schedule), label: '最新'),

          NavigationDestination(
            icon: _messageIcon(Icons.mail_outline),
            selectedIcon: _messageIcon(Icons.mail),
            label: 'メッセージ',
          ),

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
