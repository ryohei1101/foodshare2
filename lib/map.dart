import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:foodshare/PostPage.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/post_model.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class FoodPin {
  const FoodPin({
    required this.id,
    required this.userId,
    required this.title,
    required this.shopName,
    required this.tags,
    required this.memo,
    required this.point,
  });

  final String id;
  final String userId;
  final String title;
  final String shopName;
  final List<String> tags;
  final String memo;
  final LatLng point;

  bool get isMine => userId == 'me';
}

class OSMMapPage extends StatefulWidget {
  const OSMMapPage({super.key, required this.email});

  final String email;

  @override
  State<OSMMapPage> createState() => _OSMMapPageState();
}

class _OSMMapPageState extends State<OSMMapPage> {
  final LatLng fakeCurrentPos = const LatLng(35.6480, 139.7430);
  final double fakeAccuracy = 50.0;
  final MapController _mapController = MapController();
  final String _currentUserId = 'me';
  final List<String> _availableTags = const [
    '和食',
    'イタリアン',
    'ラーメン',
    'カフェ',
    '居酒屋',
    'スイーツ',
    'ランチ',
    'ディナー',
  ];
  final List<FoodPin> _pins = [
    FoodPin(
      id: 'sample-1',
      userId: 'other-user',
      title: '夜ごはん向け',
      shopName: 'サンプル食堂',
      tags: ['和食', 'ディナー'],
      memo: '落ち着いていて入りやすい。',
      point: const LatLng(35.6486, 139.7424),
    ),
    FoodPin(
      id: 'sample-2',
      userId: 'other-user-2',
      title: '軽く飲みたい時',
      shopName: '港バル',
      tags: ['居酒屋'],
      memo: '一人でも入りやすい。',
      point: const LatLng(35.6472, 139.7443),
    ),
  ];
  LatLng? _pendingPinPoint;
  List<FoodPost> _postPins = [];
  String? _selectedLocationFilter;
  String? _selectedPriceFilter;
  String? _selectedCategoryFilter;
  String? _selectedTagFilter;

  final List<String> _priceFilters = const [
    "~2000円",
    "2000~3000円",
    "3000円~4000円",
    "4000~5000円",
    "5000~6000円",
    "6000~7000円",
    "7000~8000円",
    "8000~9000円",
    "9000円~10000円",
    "10000~15000円",
    "15000~20000円",
    "20000~30000円",
    "30000円以上",
  ];

  final List<String> _categoryFilters = const [
    '和食',
    '洋食',
    '中華',
    'スイーツ',
    'ドリンク',
    'その他',
  ];

  final List<String> _tagFilters = const [
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
    "#ディナー",
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _mapController.move(fakeCurrentPos, 17);
    });
    _fetchPostPins();
  }

  Future<void> _fetchPostPins() async {
    try {
      final query = <String, String>{
        'limit': '200',
        if (_selectedLocationFilter != null &&
            _selectedLocationFilter!.trim().isNotEmpty)
          'location': _selectedLocationFilter!.trim(),
        if (_selectedPriceFilter != null) 'price_range': _selectedPriceFilter!,
        if (_selectedCategoryFilter != null)
          'category': _selectedCategoryFilter!,
        if (_selectedTagFilter != null) 'tag': _selectedTagFilter!,
      };
      final response = await http.get(
        Uri.http('10.0.2.2:8000', '/posts', query),
      );

      if (!mounted || response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final posts = data['posts'] as List<dynamic>? ?? [];

      setState(() {
        _postPins = posts
            .map((post) => FoodPost.fromJson(post as Map<String, dynamic>))
            .where((post) => post.latitude != null && post.longitude != null)
            .toList();
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  List<List<FoodPost>> get _postGroups {
    final groups = <String, List<FoodPost>>{};

    for (final post in _postPins) {
      final lat = post.latitude?.toStringAsFixed(5) ?? '';
      final lon = post.longitude?.toStringAsFixed(5) ?? '';
      final key = '${post.shopName}|$lat|$lon';
      groups.putIfAbsent(key, () => []).add(post);
    }

    for (final posts in groups.values) {
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return groups.values.toList();
  }

  Future<void> _showCreatePinDialog(LatLng point) async {
    final titleController = TextEditingController();
    final shopNameController = TextEditingController();
    final memoController = TextEditingController();
    final selectedTags = <String>{};

    final createdPin = await showDialog<FoodPin>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('ピンを追加'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '緯度 ${point.latitude.toStringAsFixed(5)} / 経度 ${point.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'タイトル',
                        hintText: '例: 一人ランチ向け',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: shopNameController,
                      decoration: const InputDecoration(
                        labelText: '店名',
                        hintText: '例: さくら食堂',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('ジャンルタグ'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (_) {
                            setDialogState(() {
                              if (isSelected) {
                                selectedTags.remove(tag);
                              } else {
                                selectedTags.add(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: memoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'メモ',
                        hintText: '例: 静かで作業しやすい',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        shopNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('タイトルと店名は必須です。')),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      FoodPin(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        userId: _currentUserId,
                        title: titleController.text.trim(),
                        shopName: shopNameController.text.trim(),
                        tags: selectedTags.toList(),
                        memo: memoController.text.trim(),
                        point: point,
                      ),
                    );
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || createdPin == null) {
      return;
    }

    setState(() {
      _pins.add(createdPin);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${createdPin.shopName}」のピンを追加しました。')),
    );
  }

  void _showPinDetail(FoodPin pin) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      pin.isMine ? Icons.bookmark : Icons.location_on,
                      color: pin.isMine ? Colors.blue : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pin.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pin.isMine
                            ? Colors.blue.withValues(alpha: 0.15)
                            : Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(pin.isMine ? '自分のピン' : '他の人のピン'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pin.shopName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (pin.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pin.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(pin.memo.isEmpty ? 'メモはありません。' : pin.memo),
                const SizedBox(height: 8),
                Text(
                  '緯度 ${pin.point.latitude.toStringAsFixed(5)} / 経度 ${pin.point.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPostPage(LatLng point) async {
    setState(() {
      _pendingPinPoint = null;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostPage(
          email: widget.email,
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      ),
    );

    if (mounted) {
      _fetchPostPins();
    }
  }

  void _showPostGroupDetail(List<FoodPost> posts) {
    final firstPost = posts.first;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              firstPost.shopName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        firstPost.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${posts.length}件の投稿',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return FoodCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFEFE3),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              title: Text(
                                post.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(post.createdAt),
                            ),
                            AspectRatio(
                              aspectRatio: 1.05,
                              child: Image.network(
                                post.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(label: Text(post.category)),
                                      Chip(label: Text(post.priceRange)),
                                      if (post.tags.isNotEmpty)
                                        Chip(label: Text(post.tags)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(post.comment),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    final locationController = TextEditingController(
      text: _selectedLocationFilter ?? '',
    );
    String? price = _selectedPriceFilter;
    String? category = _selectedCategoryFilter;
    String? tag = _selectedTagFilter;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '条件で探す',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: '場所',
                          hintText: '例: 港区、渋谷区',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: price,
                        hint: const Text('価格帯'),
                        items: _priceFilters
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            price = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        hint: const Text('カテゴリ'),
                        items: _categoryFilters
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            category = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: tag,
                        hint: const Text('タグ'),
                        items: _tagFilters
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            tag = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedLocationFilter =
                                locationController.text.trim().isEmpty
                                ? null
                                : locationController.text.trim();
                            _selectedPriceFilter = price;
                            _selectedCategoryFilter = category;
                            _selectedTagFilter = tag;
                          });
                          Navigator.pop(context);
                          _fetchPostPins();
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('検索する'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedLocationFilter = null;
                            _selectedPriceFilter = null;
                            _selectedCategoryFilter = null;
                            _selectedTagFilter = null;
                          });
                          Navigator.pop(context);
                          _fetchPostPins();
                        },
                        child: const Text('条件をクリア'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: fakeCurrentPos,
            initialZoom: 17,
            onTap: (_, point) {
              setState(() {
                _pendingPinPoint = point;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.07ryohe1101.foooood',
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: fakeCurrentPos,
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderStrokeWidth: 1,
                  borderColor: Colors.blue.withValues(alpha: 0.5),
                  useRadiusInMeter: true,
                  radius: fakeAccuracy,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: fakeCurrentPos,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                ..._pins.map(
                  (pin) => Marker(
                    point: pin.point,
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => _showPinDetail(pin),
                      child: Icon(
                        pin.isMine ? Icons.bookmark : Icons.location_on,
                        color: pin.isMine ? Colors.blue : Colors.redAccent,
                        size: pin.isMine ? 34 : 38,
                      ),
                    ),
                  ),
                ),
                ..._postGroups.map(
                  (posts) => Marker(
                    point: LatLng(
                      posts.first.latitude!,
                      posts.first.longitude!,
                    ),
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => _showPostGroupDetail(posts),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.restaurant,
                            color: Colors.deepOrange,
                            size: 36,
                          ),
                          if (posts.length > 1)
                            Positioned(
                              top: 0,
                              right: 2,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Text(
                                    '${posts.length}',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_pendingPinPoint != null)
                  Marker(
                    point: _pendingPinPoint!,
                    width: 46,
                    height: 46,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.orangeAccent,
                      size: 38,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton.small(
            heroTag: 'map-filter',
            backgroundColor: Colors.white,
            foregroundColor: foodPrimary,
            onPressed: _showFilterSheet,
            child: const Icon(Icons.search),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '地図をタップして候補位置を選択',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('青: 自分  赤: 他の人', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        if (_pendingPinPoint != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'この場所にピンを立てますか？',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '緯度 ${_pendingPinPoint!.latitude.toStringAsFixed(5)} / 経度 ${_pendingPinPoint!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _pendingPinPoint = null;
                              });
                            },
                            child: const Text('キャンセル'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final point = _pendingPinPoint;
                              if (point == null) {
                                return;
                              }
                              _openPostPage(point);
                            },
                            child: const Text('投稿する'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          final point = _pendingPinPoint;
                          if (point == null) {
                            return;
                          }
                          setState(() {
                            _pendingPinPoint = null;
                          });
                          _showCreatePinDialog(point);
                        },
                        child: const Text('ピンを立てる'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
