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

  void _goToAccount() {
    setState(() {
      _selectedIndex = 4;
    });
  }

  // Hàm xử lý đặt nhắc nhở uống thuốc
  Future<void> _setMedicationReminder() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: "CHỌN GIỜ UỐNG THUỐC",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimaryColor),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      String medicineName = "";
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Nhắc nhở uống thuốc"),
          content: TextField(
            autofocus: true,
            onChanged: (value) => medicineName = value,
            decoration: const InputDecoration(
              hintText: "Ví dụ: Paracetamol, Vitamin C...",
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kPrimaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("HỦY"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              onPressed: () {
                if (medicineName.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _confirmReminder(medicineName, pickedTime);
                }
              },
              child: const Text(
                "ĐẶT LỊCH",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _confirmReminder(String name, TimeOfDay time) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Đã đặt nhắc nhở: $name lúc ${time.format(context)}"),
        backgroundColor: kPrimaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Widget> _getWidgetOptions() {
    return [
      HomePageContent(
        onReminderTap: _setMedicationReminder,
        onAvatarTap: _goToAccount,
      ),
      const HistoryScreen(),
      const SizedBox.shrink(), // Vị trí nút Scan (index 2)
      const ServiceScreen(), // Màn hình Dịch vụ (index 3)
      const AccountScreen(), // Màn hình Tài khoản (index 4)
    ];
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      OnnxPipeline().init();
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() {
      _selectedIndex = index;
    });
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
      if (imageFile == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );

      try {
        String extractedText = await OnnxPipeline().runPipeline(imageFile.path);
        if (!mounted) return;
        Navigator.pop(context);

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
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _selectedIndex, children: _getWidgetOptions()),
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
        backgroundColor: kPrimaryColor,
        shape: const CircleBorder(),
        elevation: 4,
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
              label: 'LỊCH SỬ',
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
            ),
          ],
        ),
      ),
    );
  }
}

// --- TRANG CHỦ CONTENT ---
class HomePageContent extends StatelessWidget {
  final VoidCallback onReminderTap;
  final VoidCallback onAvatarTap;

  const HomePageContent({
    super.key,
    required this.onReminderTap,
    required this.onAvatarTap,
  });

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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
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
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 30),
              onPressed: () {},
            ),
            GestureDetector(
              onTap: onAvatarTap,
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: kPrimaryLightColor,
                child: Icon(Icons.person, color: kPrimaryColor, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridMenu() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildGridItem(
          icon: Icons.alarm,
          label: 'NHẮC NHỞ',
          isSpecial: true,
          onTap: onReminderTap,
        ),
        _buildGridItem(icon: Icons.calendar_today, label: 'LỊCH KHÁM'),
        _buildGridItem(icon: Icons.more_horiz, label: 'THÊM'),
      ],
    );
  }

  Widget _buildGridItem({
    IconData? icon,
    String? label,
    bool isSpecial = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSpecial ? kPrimaryLightColor : kGridBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.help_outline,
              color: isSpecial ? kPrimaryColor : kInactiveColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label ?? "",
              style: TextStyle(
                color: isSpecial ? kPrimaryColor : kInactiveColor,
                fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- TRANG DỊCH VỤ (Đã sửa lỗi Const) ---
class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Dịch vụ y tế",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServiceItem(
            Icons.local_hospital,
            "Đặt lịch khám",
            "Kết nối với bác sĩ nhanh chóng",
          ),
          _buildServiceItem(
            Icons.chat,
            "Tư vấn bác sĩ",
            "Giải đáp thắc mắc sức khỏe 24/7",
          ),
          _buildServiceItem(
            Icons.medication,
            "Mua thuốc online",
            "Giao thuốc tận nhà trong 2h",
          ),
          _buildServiceItem(
            Icons.search,
            "Tra cứu bệnh lý",
            "Thông tin y khoa chính xác",
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      color: kGridBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kPrimaryLightColor,
          child: Icon(icon, color: kPrimaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: kInactiveColor),
        onTap: () {
          // Xử lý logic khi click vào dịch vụ
        },
      ),
    );
  }
}
