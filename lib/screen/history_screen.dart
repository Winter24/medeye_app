import 'package:flutter/material.dart';

// --- Constants ---
const Color kPrimaryColor = Color(0xFFB58BFF);
const Color kPrimaryLightColor = Color(0xFFE6DFFD);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Biến state để theo dõi ngày đang được chọn. Mặc định là ngày 19.
  int _selectedDate = 19;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Màu nền xám nhạt
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 20),
                _buildDateScroller(),
                const SizedBox(height: 30),
                _buildPrescriptionList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng phần header màu tím với tiêu đề và thanh tìm kiếm
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6DFFD), Color(0xFFD0BFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử khám',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  /// Xây dựng thanh tìm kiếm
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm đơn khám...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.filter_list, color: kPrimaryColor),
        ),
      ],
    );
  }

  /// Xây dựng bộ chọn tháng/năm
  Widget _buildMonthSelector() {
    return Row(
      children: [
        const Text(
          'Tháng 10/2025',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Icon(Icons.arrow_drop_down, color: Colors.black54),
      ],
    );
  }

  /// Xây dựng thanh cuộn chọn ngày
  Widget _buildDateScroller() {
    // Dữ liệu mẫu cho các ngày trong tuần
    final List<Map<String, dynamic>> dates = [
      {'day': 'Thứ 7', 'date': 18},
      {'day': 'CN', 'date': 19},
      {'day': 'Thứ 2', 'date': 20},
      {'day': 'Thứ 3', 'date': 21},
      {'day': 'Thứ 4', 'date': 22},
      {'day': 'Thứ 5', 'date': 23},
      {'day': 'Thứ 6', 'date': 24},
    ];

    return Row(
      children: [
        const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dates.map((date) {
                final bool isSelected = date['date'] == _selectedDate;
                return _buildDateItem(
                  day: date['day'],
                  date: date['date'].toString(),
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedDate = date['date'];
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    );
  }

  /// Widget cho một ngày trong thanh cuộn
  Widget _buildDateItem({
    required String day,
    required String date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng danh sách các đơn khám
  Widget _buildPrescriptionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Đơn khám của bạn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 30),
        const Text(
          'Thứ 3, Ngày 19/10/2025',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        _buildPrescriptionCard(
          icon: Icons.medication,
          iconColor: const Color(0xFFFACC15), // Màu vàng
          title: 'ĐƠN THUỐC',
          details: [
            'Nơi khám: Bệnh Viện Mắt VISI',
            'Chẩn đoán: Viêm giác mạc...',
          ],
          purchaseDate: '19/10/2025',
        ),
        const SizedBox(height: 16),
        _buildPrescriptionCard(
          icon: Icons.visibility_outlined,
          iconColor: kPrimaryColor, // Màu tím
          title: 'ĐƠN KÍNH',
          details: [
            'Nơi Bán: Bệnh Viện Mắt VISI',
            'Chẩn đoán: Mắt trái 2 độ, Mắt phải...',
          ],
          purchaseDate: '19/10/2025',
        ),
      ],
    );
  }

  /// Widget cho một thẻ đơn khám
  Widget _buildPrescriptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> details,
    required String purchaseDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.join('\n'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày mua: $purchaseDate',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Row(
                children: [
                  Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.black87,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
