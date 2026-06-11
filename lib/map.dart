import 'dart:math' as math;

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:foodshare/PostPage.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/genre_options.dart';
import 'package:foodshare/map_focus_store.dart';
import 'package:foodshare/map_selection_store.dart';
import 'package:foodshare/post_attributes.dart';
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
  LatLng? _focusedPoint;
  String _focusedLabel = '';
  LatLng? _searchCenter;
  List<List<FoodPost>> _postGroups = [];
  final Set<String> _checkedShopKeys = {};
  String? _selectedPriceFilter;
  String? _selectedCategoryFilter;
  String? _selectedTagFilter;
  final List<Offset> _circleGesturePoints = [];
  final ValueNotifier<List<Offset>> _circleGestureTrace =
      ValueNotifier<List<Offset>>(const []);
  bool _isFilterSheetOpen = false;
  static const double _searchRadiusKm = 1.0;

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

  @override
  void initState() {
    super.initState();
    MapFocusStore.request.addListener(_handleMapFocusRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final request = MapFocusStore.request.value;
      if (request == null) {
        _mapController.move(fakeCurrentPos, 17);
        return;
      }

      _focusOnPoint(request.point, label: request.label);
    });
    _fetchPostPins();
  }

  @override
  void dispose() {
    MapFocusStore.request.removeListener(_handleMapFocusRequest);
    _circleGestureTrace.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchCenter != null ||
      _selectedPriceFilter != null ||
      _selectedCategoryFilter != null ||
      _selectedTagFilter != null;

  bool get _hasResettableMapState =>
      _hasActiveFilters || _focusedPoint != null || _pendingPinPoint != null;

  void _handleMapFocusRequest() {
    final request = MapFocusStore.request.value;
    if (!mounted || request == null) {
      return;
    }

    _focusOnPoint(request.point, label: request.label);
  }

  void _focusOnPoint(LatLng point, {String label = ''}) {
    setState(() {
      _focusedPoint = point;
      _focusedLabel = label;
      _pendingPinPoint = null;
    });
    _mapController.move(point, 18);
  }

  void _clearFilters() {
    setState(() {
      _searchCenter = null;
      _focusedPoint = null;
      _focusedLabel = '';
      _pendingPinPoint = null;
      _selectedPriceFilter = null;
      _selectedCategoryFilter = null;
      _selectedTagFilter = null;
    });
    _fetchPostPins();
  }

  Future<void> _fetchPostPins() async {
    try {
      final query = <String, String>{
        'limit': '200',
        'viewer_email': widget.email,
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
        final nextPostPins = posts
            .map((post) => FoodPost.fromJson(post as Map<String, dynamic>))
            .where((post) => post.latitude != null && post.longitude != null)
            .where((post) {
              if (_searchCenter == null) {
                return true;
              }
              final distanceKm = const Distance().as(
                LengthUnit.Kilometer,
                _searchCenter!,
                LatLng(post.latitude!, post.longitude!),
              );
              return distanceKm <= _searchRadiusKm;
            })
            .toList();
        _postGroups = _groupPosts(nextPostPins);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  List<List<FoodPost>> _groupPosts(List<FoodPost> postsToGroup) {
    final groups = <String, List<FoodPost>>{};

    for (final post in postsToGroup) {
      final lat = post.latitude?.toStringAsFixed(5) ?? '';
      final lon = post.longitude?.toStringAsFixed(5) ?? '';
      final key = '$lat|$lon';
      groups.putIfAbsent(key, () => []).add(post);
    }

    for (final posts in groups.values) {
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return groups.values.toList();
  }

  String _majorityShopName(List<FoodPost> posts) {
    final counts = <String, int>{};

    for (final post in posts) {
      final name = post.shopName.trim();
      if (name.isEmpty || name == '店名未設定') {
        continue;
      }
      counts[name] = (counts[name] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return posts.first.shopName;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.key.compareTo(b.key);
      });

    return entries.first.key;
  }

  String _shopKey(String shopName, LatLng point) {
    return [
      shopName.trim().toLowerCase(),
      point.latitude.toStringAsFixed(5),
      point.longitude.toStringAsFixed(5),
    ].join('|');
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

  Future<void> _openPostPage(LatLng point, {String? initialShopName}) async {
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
          initialShopName: initialShopName,
        ),
      ),
    );

    if (mounted) {
      _fetchPostPins();
    }
  }

  void _showPostGroupDetail(List<FoodPost> posts) {
    final firstPost = posts.first;
    final shopName = _majorityShopName(posts);
    final point = LatLng(firstPost.latitude!, firstPost.longitude!);
    final shopKey = _shopKey(shopName, point);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isChecked = _checkedShopKeys.contains(shopKey);
            final isPollSelected = MapSelectionStore.containsPollSelection(
              shopKey,
            );

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
                              Icon(
                                Icons.restaurant,
                                color: isChecked
                                    ? Colors.blue
                                    : Colors.deepOrange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  shopName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: isChecked ? 'チェック解除' : 'チェック',
                                onPressed: () {
                                  setState(() {
                                    if (isChecked) {
                                      _checkedShopKeys.remove(shopKey);
                                    } else {
                                      _checkedShopKeys.add(shopKey);
                                    }
                                  });
                                  setSheetState(() {});
                                },
                                icon: Icon(
                                  isChecked
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                tooltip: isPollSelected
                                    ? 'アンケート候補から外す'
                                    : 'アンケート候補に追加',
                                style: IconButton.styleFrom(
                                  backgroundColor: isPollSelected
                                      ? Colors.orange
                                      : null,
                                  foregroundColor: isPollSelected
                                      ? Colors.white
                                      : null,
                                ),
                                onPressed: () {
                                  MapSelectionStore.togglePollSelection(
                                    MapShopSelection(
                                      key: shopKey,
                                      shopName: shopName,
                                      location: firstPost.location,
                                      point: point,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isPollSelected
                                            ? 'アンケート候補から外しました'
                                            : 'アンケート候補に追加しました',
                                      ),
                                    ),
                                  );
                                  setSheetState(() {});
                                },
                                icon: Icon(
                                  isPollSelected
                                      ? Icons.how_to_vote
                                      : Icons.how_to_vote_outlined,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                tooltip: 'この店舗に投稿',
                                onPressed: () {
                                  Navigator.pop(context);
                                  _openPostPage(
                                    point,
                                    initialShopName: shopName,
                                  );
                                },
                                icon: const Icon(Icons.add_a_photo_outlined),
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
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [Text(post.comment)],
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
      },
    );
  }

  Future<void> _showFilterSheet({LatLng? searchCenter}) async {
    if (_isFilterSheetOpen) {
      return;
    }

    _isFilterSheetOpen = true;
    if (searchCenter != null) {
      setState(() {
        _searchCenter = searchCenter;
      });
      _mapController.move(searchCenter, 16);
    }

    String? price = _selectedPriceFilter;
    String? category = _selectedCategoryFilter;
    String? tag = _selectedTagFilter;

    try {
      await showModalBottomSheet<void>(
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
                          '周辺の条件で探す',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '場所',
                          style: TextStyle(
                            color: foodInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchCenter == null
                              ? '現在表示している地図周辺から探します。'
                              : '囲った中心から1km周辺を探します。',
                          style: const TextStyle(
                            color: foodMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '誰と',
                          style: TextStyle(
                            color: foodInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CompanionFilterSelector(
                          value: isCompanionAttribute(tag) ? tag : null,
                          onChanged: (value) {
                            setSheetState(() {
                              tag = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ジャンル',
                          style: TextStyle(
                            color: foodInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FoodGenreSelector(
                          value: category,
                          recommendedGenreNames:
                              recommendedGenreNamesForCompanion(tag),
                          onChanged: (value) {
                            setSheetState(() {
                              category = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '価格',
                          style: TextStyle(
                            color: foodInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                        const Text(
                          '席・喫煙',
                          style: TextStyle(
                            color: foodInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        PostAttributeFilterSelector(
                          value: isCompanionAttribute(tag) ? null : tag,
                          groups: facilityAttributeGroups,
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
                              _searchCenter ??= _mapController.camera.center;
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
                              _searchCenter = null;
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
    } finally {
      _isFilterSheetOpen = false;
    }
  }

  void _startCircleGesture(Offset point) {
    if (_isFilterSheetOpen) {
      return;
    }

    _circleGestureTrace.value = const [];
    _circleGesturePoints
      ..clear()
      ..add(point);
  }

  void _updateCircleGesture(Offset point) {
    if (_isFilterSheetOpen) {
      return;
    }

    final shouldShowTrace =
        _circleGesturePoints.isNotEmpty &&
        (point - _circleGesturePoints.first).distance > 14;

    _circleGesturePoints.add(point);

    if (shouldShowTrace) {
      _circleGestureTrace.value = List<Offset>.unmodifiable(
        _circleGesturePoints,
      );
    }
  }

  void _clearCircleGestureTrace() {
    _circleGesturePoints.clear();
    _circleGestureTrace.value = const [];
  }

  void _finishCircleGesture() {
    if (_isFilterSheetOpen || _circleGesturePoints.length < 10) {
      _clearCircleGestureTrace();
      return;
    }

    final first = _circleGesturePoints.first;
    final last = _circleGesturePoints.last;
    final closeDistance = (last - first).distance;
    final xs = _circleGesturePoints.map((point) => point.dx);
    final ys = _circleGesturePoints.map((point) => point.dy);
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);
    final width = maxX - minX;
    final height = maxY - minY;
    final ratio = height == 0 ? 0.0 : width / height;
    final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    var totalAngle = 0.0;
    var pathLength = 0.0;

    double angleOf(Offset point) {
      return math.atan2(point.dy - center.dy, point.dx - center.dx);
    }

    var previousAngle = angleOf(_circleGesturePoints.first);
    for (var i = 1; i < _circleGesturePoints.length; i += 1) {
      pathLength +=
          (_circleGesturePoints[i] - _circleGesturePoints[i - 1]).distance;
      final nextAngle = angleOf(_circleGesturePoints[i]);
      var delta = nextAngle - previousAngle;
      while (delta > math.pi) {
        delta -= math.pi * 2;
      }
      while (delta < -math.pi) {
        delta += math.pi * 2;
      }
      totalAngle += delta;
      previousAngle = nextAngle;
    }

    _clearCircleGestureTrace();

    final maxSide = math.max(width, height);
    final isCircleLike =
        width >= 70 &&
        height >= 70 &&
        ratio >= 0.45 &&
        ratio <= 2.2 &&
        pathLength >= maxSide * 1.8 &&
        (closeDistance <= maxSide * 0.85 || totalAngle.abs() >= math.pi * 1.35);

    if (!isCircleLike) {
      return;
    }

    final centerPoint = _mapController.camera.pointToLatLng(
      math.Point(center.dx, center.dy),
    );

    _showFilterSheet(searchCenter: centerPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Listener(
          onPointerDown: (event) => _startCircleGesture(event.localPosition),
          onPointerMove: (event) => _updateCircleGesture(event.localPosition),
          onPointerUp: (_) => _finishCircleGesture(),
          onPointerCancel: (_) {
            _clearCircleGestureTrace();
          },
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: fakeCurrentPos,
              initialZoom: 17,
              onTap: (_, point) {
                setState(() {
                  _pendingPinPoint = point;
                  _focusedPoint = null;
                  _focusedLabel = '';
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
              if (_searchCenter != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _searchCenter!,
                      radius: _searchRadiusKm * 1000,
                      useRadiusInMeter: true,
                      color: foodPrimary.withValues(alpha: 0.10),
                      borderColor: foodPrimary,
                      borderStrokeWidth: 2,
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
                  ..._postGroups.map((posts) {
                    final point = LatLng(
                      posts.first.latitude!,
                      posts.first.longitude!,
                    );
                    final shopName = _majorityShopName(posts);
                    final isChecked = _checkedShopKeys.contains(
                      _shopKey(shopName, point),
                    );

                    return Marker(
                      point: point,
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => _showPostGroupDetail(posts),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.restaurant,
                              color: isChecked
                                  ? Colors.blue
                                  : Colors.deepOrange,
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
                                      style: TextStyle(
                                        color: isChecked
                                            ? Colors.blue
                                            : Colors.deepOrange,
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
                    );
                  }),
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
                  if (_focusedPoint != null)
                    Marker(
                      point: _focusedPoint!,
                      width: 58,
                      height: 58,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.blueAccent,
                        size: 48,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<List<Offset>>(
              valueListenable: _circleGestureTrace,
              builder: (context, points, _) {
                if (points.length < 2) {
                  return const SizedBox.shrink();
                }

                return CustomPaint(
                  painter: _CircleSearchPainter(points: points),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Row(
            children: [
              _MapControlButton(
                icon: Icons.search,
                label: '検索',
                onPressed: () => _showFilterSheet(),
              ),
              const SizedBox(width: 10),
              if (_hasResettableMapState)
                _MapControlButton(
                  icon: Icons.close,
                  label: 'リセット',
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  onPressed: _clearFilters,
                ),
            ],
          ),
        ),
        if (_focusedPoint != null && _focusedLabel.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            top: 74,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, color: foodPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _focusedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
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

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor = Colors.white,
    this.foregroundColor = foodPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: foregroundColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleSearchPainter extends CustomPainter {
  const _CircleSearchPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final paint = Paint()
      ..color = foodPrimary.withValues(alpha: 0.72)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleSearchPainter oldDelegate) {
    return true;
  }
}
