import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:foodshare/PostPage.dart';
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

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _mapController.move(fakeCurrentPos, 17);
    });
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

  void _openPostPage(LatLng point) {
    setState(() {
      _pendingPinPoint = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostPage(
          email: widget.email,
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      ),
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
