import 'package:flutter/material.dart';
import 'dart:io';
import 'package:foodshare/app_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final String email;
  final String birthday;
  final String profileImage;

  const ProfilePage({
    super.key,
    required this.email,
    required this.birthday,
    required this.profileImage,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ⭐ 選択画像
  File? selectedImage;

  final List<String> postImages = ['assets/qualify.png', 'assets/pasta.png'];

  // ⭐ 年齢計算
  int? calculateAge(String birthday) {
    final birth = DateTime.tryParse(birthday);

    if (birth == null) {
      return null;
    }

    final today = DateTime.now();

    int age = today.year - birth.year;

    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }

    return age;
  }

  // ⭐ 画像アップロード
  Future<void> uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',

      Uri.parse("http://10.0.2.2:8000/upload-profile-image"),
    );

    // ⭐ email送信
    request.fields['email'] = widget.email;

    // ⭐ file送信
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      debugPrint("upload success");
    } else {
      debugPrint("upload failed");
    }
  }

  // ⭐ 画像選択
  Future<void> pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File pickedFile = File(image.path);

      setState(() {
        selectedImage = pickedFile;
      });

      // ⭐ FastAPIへ送信
      await uploadImage(pickedFile);
    }
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final age = calculateAge(widget.birthday);

    return Scaffold(
      appBar: AppBar(elevation: 0, title: const Text('Profile')),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ⭐ プロフィール画像
            Stack(
              children: [
                Container(
                  width: 152,
                  height: 152,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    gradient: LinearGradient(
                      colors: [foodPrimary, const Color(0xFFFFC285)],
                    ),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(6),

                    child: ClipOval(
                      child: selectedImage != null
                          // ⭐ ローカル画像
                          ? Image.file(selectedImage!, fit: BoxFit.cover)
                          // ⭐ DB画像
                          : Image.network(
                              widget.profileImage.isNotEmpty
                                  ? "http://10.0.2.2:8000/${widget.profileImage}"
                                  : "http://10.0.2.2:8000/uploads/cutiestreet.png",

                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),

                // ⭐ 右下プラスボタン
                Positioned(
                  bottom: 5,
                  right: 5,

                  child: GestureDetector(
                    onTap: pickImage,

                    child: Container(
                      width: 45,
                      height: 45,

                      decoration: BoxDecoration(
                        color: foodPrimary,

                        shape: BoxShape.circle,

                        border: Border.all(color: Colors.white, width: 3),
                      ),

                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ⭐ 情報カード
            FoodCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        "Age :",

                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Text(age == null ? "-" : "$age years"),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        "ID:",

                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Flexible(
                        child: Text(
                          widget.email,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ⭐ タブ
            TabBar(
              controller: _tabController,

              indicatorColor: Colors.orangeAccent,

              tabs: const [
                Tab(text: "投稿"),
                Tab(text: "検索"),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,

                children: [
                  GridView.builder(
                    padding: const EdgeInsets.all(4),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),

                    itemCount: postImages.length,

                    itemBuilder: (context, i) {
                      return Image.asset(postImages[i], fit: BoxFit.cover);
                    },
                  ),

                  const Center(child: Text("検索画面")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
