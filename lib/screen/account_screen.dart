import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Constants ---
const Color kPrimaryColor = Color(0xFFB58BFF);
const Color kPrimaryLightColor = Color(0xFFE6DFFD);

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final String _imageKey = "user_avatar_path";

  @override
  void initState() {
    super.initState();
    _loadImage(); // Tải ảnh đã lưu khi vừa vào màn hình
  }

  // Đọc đường dẫn ảnh từ máy
  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString(_imageKey);
    if (imagePath != null && imagePath.isNotEmpty) {
      if (File(imagePath).existsSync()) {
        setState(() {
          _imageFile = File(imagePath);
        });
      }
    }
  }

  // Chọn ảnh và Lưu đường dẫn
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Lưu bền vững vào máy
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_imageKey, pickedFile.path);
      }
    } catch (e) {
      debugPrint("Lỗi khi chọn ảnh: $e");
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: kPrimaryColor),
                title: const Text('Thư viện ảnh'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: kPrimaryColor),
                title: const Text('Máy ảnh'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const avatarRadius = 50.0;
    final double headerBoundary = screenHeight * 0.22;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Container(
            height: headerBoundary,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE6DFFD), Color(0xFFD0BFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    'Tài khoản',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: headerBoundary),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35.0)),
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, avatarRadius + 24, 24, 24),
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    text: 'Hồ sơ cá nhân',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.shopping_cart_outlined,
                    text: 'Đơn hàng',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    text: 'Các câu hỏi thường gặp',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FAQScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    text: 'Về chúng tôi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    text: 'Đăng xuất',
                    isLogout: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'Phiên bản 1.1.1',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: headerBoundary - avatarRadius,
            left: screenWidth / 2 - avatarRadius,
            child: GestureDetector(
              onTap: _showPickerOptions,
              child: _buildAvatar(avatarRadius),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double radius) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: kPrimaryLightColor,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!) as ImageProvider
              : const NetworkImage(
                  'https://images.unsplash.com/photo-1580489944761-15a19d654956?ixlib=rb-4.0.3&auto=format&fit=crop&w=761&q=80',
                ),
        ),
        Positioned(
          bottom: 2,
          right: -4,
          child: Container(
            height: 35,
            width: 35,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final Color iconColor = isLogout ? Colors.red : kPrimaryColor;
    final Color iconBackgroundColor = isLogout
        ? const Color(0xFFFEEEEE)
        : kPrimaryLightColor;
    final Color textColor = isLogout ? Colors.red : Colors.black87;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }
}

// Giữ nguyên FAQScreen và AboutUsScreen phía dưới...
// --- 1. MÀN HÌNH FAQ ---
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Câu hỏi thường gặp',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            '1. Giá sử dụng',
            'MedEye có miễn phí không?',
            'MedEye có phiên bản miễn phí. Một số tính năng nâng cao có thể cần trả phí tùy gói sử dụng.',
          ),
          _buildFAQItem(
            '2. Bảo mật thông tin',
            'Thông tin sức khỏe có an toàn không?',
            'MedEye cam kết bảo mật thông tin người dùng và chỉ sử dụng dữ liệu để hỗ trợ chăm sóc sức khỏe mắt.',
          ),
          _buildFAQItem(
            '3. Hỗ trợ & phản hồi',
            'Gặp lỗi thì liên hệ ở đâu?',
            'Người dùng có thể gửi phản hồi trực tiếp trong app, đội ngũ MedEye sẽ hỗ trợ sớm nhất.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String category, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: kPrimaryLightColor),
      ),
      elevation: 0,
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          category,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(question, style: const TextStyle(fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.black54, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. MÀN HÌNH ABOUT US ---
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Về chúng tôi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: kPrimaryLightColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 50,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dự án MedEye',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chúng tôi là 1 nhóm sinh viên FPTU Cần Thơ thực hiện đồ án môn khởi nghiệp EXE.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryLightColor),
              ),
              child: const Text(
                'MedEye là ứng dụng y tế hỗ trợ chăm sóc mắt, nhóm tập trung xây dựng quy trình hướng dẫn thao tác rõ ràng, kịch bản tư vấn ngắn gọn và chăm sóc khách hàng sau sử dụng nhằm tạo sự tin tưởng và khuyến khích khách hàng tiếp tục sử dụng dịch vụ.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '© 2026 MedEye Team - FPT University CT',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
