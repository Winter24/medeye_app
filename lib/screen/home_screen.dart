import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:medeye_app/service/ocr_service.dart';
import 'package:medeye_app/screen/account_screen.dart';
import 'package:medeye_app/screen/history_screen.dart';
import 'package:medeye_app/screen/scan_result_screen.dart';

// --- Constants ---
const Color kPrimaryColor = Color(0xFFB58BFF);
const Color kPrimaryLightColor = Color(0xFFE6DFFD);
const Color kInactiveColor = Colors.grey;
const Color kGridBackgroundColor = Color(0xFFF5F5F5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePageContent(),
    HistoryScreen(),
    Center(child: Text('Quét giấy khám')),
    Center(child: Text('Dịch vụ')),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      print("Pre-loading AI Models...");
      OnnxPipeline().init();
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  String _sanitizeOcrText(String text) {
    List<String> lines = text.split('\n');
    List<String> sensitiveKeywords = [
      'họ tên',
      'địa chỉ',
      'địa chi',
      'số thẻ',
      'bảo hiểm',
      'bhyt',
      'mã số',
    ];

    return lines
        .where((line) {
          String lowerLine = line.toLowerCase();
          for (var key in sensitiveKeywords) {
            if (lowerLine.contains(key)) return false;
          }
          return true;
        })
        .join('\n')
        .trim();
  }

  Future<void> _scanMedicalBill() async {
    final ImagePicker picker = ImagePicker();

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Scan ảnh từ:'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Chụp đơn thuốc'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Row(
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 8),
                  Text('Chọn ảnh trong máy'),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (source != null) {
      final XFile? imageFile = await picker.pickImage(source: source);

      if (imageFile == null) {
        print("Không có ảnh nào được chọn");
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: Text(
                  "Đang phân tích đơn thuốc...",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );

      try {
        String extractedText = await OnnxPipeline().runPipeline(imageFile.path);

        String sanitizedText = _sanitizeOcrText(extractedText);

        // 5. Tắt Loading
        if (!mounted) return;
        Navigator.pop(context);

        // 6. Chuyển sang màn hình kết quả
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(
              imagePath: imageFile.path,
              rawOcrText: extractedText,
            ),
          ),
        );
      } catch (e) {
        // Xử lý lỗi nếu AI crash
        if (!mounted) return;
        Navigator.pop(context); // Tắt loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý AI: $e'),
            backgroundColor: Colors.red,
          ),
        );
        print("AI Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: _buildScanFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildScanFab() {
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        onPressed: _scanMedicalBill,
        elevation: 4.0,
        backgroundColor: kPrimaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.fullscreen, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      elevation: 20.0,
      color: Colors.white,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildNavItem(
              icon: Icons.home_outlined,
              label: 'TRANG CHỦ',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.assignment_outlined,
              label: 'LỊCH SỬ KHÁM',
              index: 1,
            ),
            const SizedBox(width: 40),
            _buildNavItem(
              icon: Icons.medication_outlined,
              label: 'DỊCH VỤ',
              index: 3,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'TÀI KHOẢN',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryColor : kInactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kPrimaryColor : kInactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET FOR THE HOME PAGE CONTENT ---
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          const SizedBox(height: 16),
          const Text(
            'Trang chủ',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 30),
          _buildGridMenu(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào buổi sáng',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Hôm nay bạn có khoẻ không?',
              style: TextStyle(color: kInactiveColor, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: kInactiveColor,
                    size: 30,
                  ),
                  onPressed: () {},
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12, right: 12),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 22,
              backgroundColor: kPrimaryLightColor,
              child: Icon(Icons.person, color: kPrimaryColor, size: 28),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridMenu() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildGridItem(icon: Icons.alarm, label: 'NHẮC NHỞ', isSpecial: true),
        _buildGridItem(),
        _buildGridItem(),
        _buildGridItem(),
        _buildGridItem(),
        _buildGridItem(),
      ],
    );
  }

  Widget _buildGridItem({
    IconData? icon,
    String? label,
    bool isSpecial = false,
  }) {
    if (isSpecial) {
      return Container(
        decoration: BoxDecoration(
          color: kPrimaryLightColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kPrimaryColor, size: 40),
            const SizedBox(height: 8),
            Text(
              label!,
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: kGridBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
