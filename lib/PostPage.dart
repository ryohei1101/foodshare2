import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  File? _selectedImage;
  String? _selectedCategory;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  final List<String> _categories = ['和食', '洋食', '中華', 'スイーツ', 'ドリンク', 'その他'];
  final List<String> _pricetags=["~2000円","2000~3000円","3000円~4000円","4000~5000円","5000~6000円","6000~7000円","7000~8000円",
  "8000~9000円","9000円~10000円","10000~15000円","15000~20000円","20000~30000円","30000円以上"];
  final List<String> _tags = [
    "#一人で",'#デート',"#友達と","#家族と",
    '#にぎやか',"#落ち着いている","#男性多め","#女性多め","#個室"
    '#ランチ',
    '#ディナー'
  ];
  String? _selectedPrice; // ✅ 価格帯選択変数を追加
  final Set<String> _selectedTags = {};

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  /// ✅ タグを追加／削除（コメント欄も同期）
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }

      // コメント欄を現在のタグに合わせて更新
      _commentController.text = _selectedTags.join(' ');
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
  }

  void _submitPost() {
    if (_selectedImage == null ||
        _selectedCategory == null ||
        _locationController.text.isEmpty ||
        _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべての項目を入力してください。')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('投稿が完了しました！(仮)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('写真を選択', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orangeAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _selectedImage == null
                    ? const Center(
                  child: Icon(Icons.add_a_photo, color: Colors.orangeAccent, size: 50),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🟠 店名
            const Text('店名を入力', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: '例: Starbucks',
                prefixIcon: const Icon(Icons.storefront),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            // 🟠 場所
            const Text('場所を入力', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: '例: 渋谷区',
                prefixIcon: const Icon(Icons.storefront),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('カテゴリを選択', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('カテゴリを選択してください'),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            const Text('価格帯を選択', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPrice,
              hint: const Text('1人あたりの価格帯を選択してください'),
              items: _pricetags.map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (val) => setState(() => _selectedPrice = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),


            const SizedBox(height: 24),

            const Text('タグを選択してコメントを作成', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 💡 トグル可能なタグボタン
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
                        color: isSelected ? Colors.white : Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor:
                    isSelected ? Colors.orangeAccent : Colors.orangeAccent.withOpacity(0.2),
                    side: const BorderSide(color: Colors.orangeAccent),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 32),

            Center(
              child: ElevatedButton.icon(
                onPressed: _submitPost,
                icon: const Icon(Icons.send),
                label: const Text('投稿する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
