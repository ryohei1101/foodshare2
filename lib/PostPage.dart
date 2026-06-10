import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodshare/app_ui.dart';
import 'package:foodshare/genre_options.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PostPage extends StatefulWidget {
  const PostPage({
    super.key,
    required this.email,
    this.latitude,
    this.longitude,
    this.initialShopName,
  });

  final String email;
  final double? latitude;
  final double? longitude;
  final String? initialShopName;

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedTags = {};

  File? _selectedImage;
  String? _selectedCategory;
  String? _selectedPrice;
  bool _isDetailStep = false;
  bool _isSubmitting = false;
  bool _isResolvingAddress = false;

  final List<String> _priceTags = const [
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

  final List<String> _tags = const [
    "#一人で",
    '#デート',
    "#友達と",
    "#家族と",
    '#にぎやか',
    "#落ち着いている",
    "#男性多め",
    "#女性多め",
    "#個室",
    '#ランチ',
    '#ディナー',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialShopName != null &&
        widget.initialShopName!.trim().isNotEmpty) {
      _shopNameController.text = widget.initialShopName!.trim();
    }
    _locationController.text = '住所を取得中...';
    _resolveSelectedAddress();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _locationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _resolveSelectedAddress() async {
    if (widget.latitude == null || widget.longitude == null) {
      _locationController.clear();
      return;
    }

    setState(() {
      _isResolvingAddress = true;
    });

    try {
      final uri = Uri.parse(
        'http://10.0.2.2:8000/reverse-geocode'
        '?latitude=${widget.latitude}&longitude=${widget.longitude}',
      );
      final response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as String? ?? '';
        _locationController.text = address.isEmpty
            ? '${widget.latitude!.toStringAsFixed(5)}, ${widget.longitude!.toStringAsFixed(5)}'
            : address;
      } else {
        _locationController.text =
            '${widget.latitude!.toStringAsFixed(5)}, ${widget.longitude!.toStringAsFixed(5)}';
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      _locationController.text =
          '${widget.latitude!.toStringAsFixed(5)}, ${widget.longitude!.toStringAsFixed(5)}';
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitPost() async {
    if (_selectedImage == null ||
        _selectedCategory == null ||
        _selectedPrice == null ||
        _shopNameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('すべての項目を入力してください。')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.0.2.2:8000/upload-post"),
      );

      request.fields['user_email'] = widget.email;
      request.fields['shop_name'] = _shopNameController.text.trim();
      request.fields['category'] = _selectedCategory!;
      request.fields['price_range'] = _selectedPrice!;
      request.fields['location'] = _locationController.text.trim();
      request.fields['comment'] = _commentController.text.trim();
      request.fields['tags'] = _selectedTags.join(' ');

      if (widget.latitude != null) {
        request.fields['latitude'] = widget.latitude.toString();
      }
      if (widget.longitude != null) {
        request.fields['longitude'] = widget.longitude.toString();
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('投稿成功！')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('投稿失敗')));
      }
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('通信エラー')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDetailStep ? '投稿内容' : '写真を選択'),
        leading: IconButton(
          onPressed: () {
            if (_isDetailStep) {
              setState(() {
                _isDetailStep = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isDetailStep ? _buildDetailStep() : _buildPhotoStep(),
    );
  }

  Widget _buildPhotoStep() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickImage,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: foodLine),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _selectedImage == null
                        ? const Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: foodPrimary,
                              size: 72,
                            ),
                          )
                        : Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('写真を選択'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _selectedImage == null
                  ? null
                  : () {
                      setState(() {
                        _isDetailStep = true;
                      });
                    },
              child: const Text('次へ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStep() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImage != null)
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 24),
            const FoodSectionTitle('店名'),
            const SizedBox(height: 8),
            TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                hintText: '例: さくら食堂',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: 24),
            const FoodSectionTitle('場所'),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: '地図で選択した地点',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            if (_isResolvingAddress) ...[
              const SizedBox(height: 8),
              const Text(
                '住所を取得しています',
                style: TextStyle(color: foodMuted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            const FoodSectionTitle('カテゴリ'),
            const SizedBox(height: 8),
            FoodGenreSelector(
              value: _selectedCategory,
              parentHint: 'ジャンルを選択してください',
              childHint: '細分類を選択してください',
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 24),
            const FoodSectionTitle('価格帯'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedPrice,
              hint: const Text('1人あたりの価格帯を選択してください'),
              items: _priceTags
                  .map(
                    (price) =>
                        DropdownMenuItem(value: price, child: Text(price)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPrice = value;
                });
              },
            ),
            const SizedBox(height: 24),
            const FoodSectionTitle('タグ'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);

                return ChoiceChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(tag),
                  selectedColor: foodPrimary,
                  backgroundColor: const Color(0xFFFFEFE3),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : foodPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  side: const BorderSide(color: foodPrimary),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const FoodSectionTitle('コメント'),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '例: 落ち着いていてランチにぴったり'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitPost,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? '投稿中' : '投稿する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
