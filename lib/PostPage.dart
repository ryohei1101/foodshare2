import 'package:flutter/material.dart';
import 'dart:io';
import 'package:foodshare/app_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PostPage extends StatefulWidget {
  final String email;

  const PostPage({super.key, required this.email});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  File? _selectedImage;

  String? _selectedCategory;

  String? _selectedPrice;

  final TextEditingController _locationController = TextEditingController();

  final TextEditingController _commentController = TextEditingController();

  final List<String> _categories = ['和食', '洋食', '中華', 'スイーツ', 'ドリンク', 'その他'];

  final List<String> _pricetags = [
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

  final List<String> _tags = [
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

  final Set<String> _selectedTags = {};

  final ImagePicker _picker = ImagePicker();

  // ⭐ 画像選択
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // ⭐ タグ追加削除
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }

      _commentController.text = _selectedTags.join(' ');

      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
  }

  // ⭐ 投稿処理
  Future<void> _submitPost() async {
    if (_selectedImage == null ||
        _selectedCategory == null ||
        _locationController.text.isEmpty ||
        _commentController.text.isEmpty ||
        _selectedPrice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('すべての項目を入力してください。')));

      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',

        Uri.parse("http://10.0.2.2:8000/upload-post"),
      );

      // ⭐ form data
      request.fields['user_email'] = widget.email;

      request.fields['category'] = _selectedCategory!;

      request.fields['price_range'] = _selectedPrice!;

      request.fields['location'] = _locationController.text;

      request.fields['comment'] = _commentController.text;

      // ⭐ image file
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );

      // ⭐ request send
      var response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('投稿成功！')));

        // ⭐ 初期化
        setState(() {
          _selectedImage = null;

          _selectedCategory = null;

          _selectedPrice = null;

          _locationController.clear();

          _commentController.clear();

          _selectedTags.clear();
        });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'お店の思い出を投稿',
              style: TextStyle(
                color: foodInk,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '写真、場所、カテゴリを入れてシェアできます。',
              style: TextStyle(color: foodMuted, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 24),

            const FoodSectionTitle('写真を選択'),

            const SizedBox(height: 8),

            GestureDetector(
              onTap: _pickImage,

              child: Container(
                height: 240,

                width: double.infinity,

                decoration: BoxDecoration(
                  border: Border.all(color: foodPrimary, width: 2),

                  borderRadius: BorderRadius.circular(12),

                  color: Colors.white,
                ),

                child: _selectedImage == null
                    ? const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          color: foodPrimary,
                          size: 50,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            const FoodSectionTitle('場所を入力'),

            const SizedBox(height: 8),

            TextField(
              controller: _locationController,

              decoration: InputDecoration(
                hintText: '例: 渋谷区',

                prefixIcon: const Icon(Icons.storefront),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const FoodSectionTitle('カテゴリを選択'),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,

              hint: const Text('カテゴリを選択してください'),

              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),

              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                });
              },

              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const FoodSectionTitle('価格帯を選択'),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _selectedPrice,

              hint: const Text('1人あたりの価格帯を選択してください'),

              items: _pricetags.map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),

              onChanged: (val) {
                setState(() {
                  _selectedPrice = val;
                });
              },

              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const FoodSectionTitle('タグを選択してコメントを作成'),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,

              runSpacing: 8,

              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);

                return GestureDetector(
                  onTap: () => _toggleTag(tag),

                  child: Chip(
                    label: Text(
                      tag,

                      style: TextStyle(
                        color: isSelected ? Colors.white : foodPrimary,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    backgroundColor: isSelected
                        ? foodPrimary
                        : const Color(0xFFFFEFE3),

                    side: const BorderSide(color: foodPrimary),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _commentController,

              maxLines: 3,

              decoration: InputDecoration(
                hintText: 'タグを押すとここに追加／削除されます',

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Center(
              child: ElevatedButton.icon(
                onPressed: _submitPost,

                icon: const Icon(Icons.send),

                label: const Text('投稿する'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: foodPrimary,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),

                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
