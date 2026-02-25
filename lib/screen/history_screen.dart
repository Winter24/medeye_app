import 'package:flutter/material.dart';
import 'package:medeye_app/service/database_service.dart';
import 'package:medeye_app/service/auth_service.dart';
import 'package:medeye_app/screen/detail_prescription_screen.dart';

// --- Constants ---
const Color kPrimaryColor = Color(0xFFB58BFF);
const Color kPrimaryLightColor = Color(0xFFE6DFFD);
const Color kAccentBlue = Color(0xFF64B5F6);
const Color kAccentRed = Color(0xFFEF5350);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedDay = DateTime.now().day;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final user = AuthService().getCurrentUser();
    final dbService = DatabaseService(uid: user?.uid);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FE,
      ), // Màu nền sáng hơn cho Dashboard
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<Prescription>>(
              stream: dbService.prescriptions,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Lỗi tải dữ liệu"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  );
                }

                final allPrescriptions = snapshot.data ?? [];

                // Logic lọc dữ liệu
                final filteredList = allPrescriptions.where((p) {
                  bool matchesDate = _searchQuery.isEmpty
                      ? (p.createdAt.day == _selectedDay)
                      : true;
                  bool matchesSearch =
                      p.hospitalName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      p.diagnose.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                  return matchesDate && matchesSearch;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 15.0,
                  ),
                  children: [
                    // --- DASHBOARD CHUYÊN NGHIỆP (Ẩn khi đang tìm kiếm) ---
                    if (_searchQuery.isEmpty) ...[
                      _buildStatsDashboard(allPrescriptions),
                      const SizedBox(height: 25),
                      _buildMonthSelector(),
                      const SizedBox(height: 15),
                      _buildDateScroller(),
                      const SizedBox(height: 25),
                    ],

                    // Tiêu đề danh sách
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _searchQuery.isEmpty
                              ? 'Hoạt động gần đây'
                              : 'Kết quả cho "$_searchQuery"',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Text(
                            '${filteredList.length} kết quả',
                            style: const TextStyle(color: kPrimaryColor),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    filteredList.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: filteredList
                                .map((p) => _buildPrescriptionCard(p))
                                .toList(),
                          ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Dashboard Thống kê KPI & Báo cáo nơi khám
  Widget _buildStatsDashboard(List<Prescription> data) {
    // Logic tính toán báo cáo
    Map<String, int> hospitalStats = {};
    for (var p in data) {
      hospitalStats[p.hospitalName] = (hospitalStats[p.hospitalName] ?? 0) + 1;
    }
    var topHospitals = hospitalStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // KPI Cards
        Row(
          children: [
            _buildKpiCard(
              "Tổng đơn",
              "${data.length}",
              Icons.description_rounded,
              kAccentBlue,
            ),
            const SizedBox(width: 15),
            _buildKpiCard(
              "Nơi khám",
              "${hospitalStats.length}",
              Icons.local_hospital_rounded,
              kAccentRed,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Report Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Báo cáo nơi khám (Tháng này)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),
              // Biểu đồ thanh đơn giản
              if (data.isEmpty)
                const Text(
                  "Chưa có dữ liệu để thống kê",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              else
                ...topHospitals
                    .take(3)
                    .map(
                      (e) =>
                          _buildHospitalRankItem(e.key, e.value, data.length),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalRankItem(String name, int count, int total) {
    double percent = count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "$count lần",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            color: kPrimaryColor,
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  /// 2. Header & Tìm kiếm
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 25, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryLightColor, Color(0xFFD0BFFF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử Medeye',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm bệnh viện, chẩn đoán...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _searchQuery = ""),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Chọn ngày thực tế
  Widget _buildDateScroller() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          DateTime date = DateTime.now().subtract(Duration(days: 3 - index));
          bool isSelected = _selectedDay == date.day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = date.day),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    date.weekday == 7 ? "CN" : "T${date.weekday + 1}",
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription p) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailPrescriptionScreen(prescription: p),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: kPrimaryLightColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_liquid_rounded,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.hospitalName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.diagnose,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() => const Row(
    children: [
      Text(
        'Tháng 02/2026',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Icon(Icons.arrow_drop_down),
    ],
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.medical_services_outlined,
          size: 60,
          color: Colors.grey[300],
        ),
        const Text(
          "Chưa có lịch sử khám bệnh",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );
}
