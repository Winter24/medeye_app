import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medeye_app/service/database_service.dart' as db;
import 'package:medeye_app/service/ai_service.dart';
import 'package:medeye_app/service/auth_service.dart';

const Color kPrimaryColor = Color(0xFFB58BFF);

class DetailPrescriptionScreen extends StatefulWidget {
  final db.Prescription prescription;

  const DetailPrescriptionScreen({super.key, required this.prescription});

  @override
  State<DetailPrescriptionScreen> createState() =>
      _DetailPrescriptionScreenState();
}

class _DetailPrescriptionScreenState extends State<DetailPrescriptionScreen> {
  String? _aiAnalysis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _aiAnalysis = widget.prescription.analysisReport;
  }

  Future<void> _runDeepAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final medsData = widget.prescription.medicines
          .map(
            (m) => {
              'brandname': m.name,
              'quantity': m.quantity,
              'usage': m.usage,
            },
          )
          .toList();

      final result = await SambaService().analyzeDeeply(
        medsData,
        widget.prescription.diagnose,
      );

      if (result != null) {
        setState(() {
          _aiAnalysis = result;
          _isLoading = false;
        });

        final user = AuthService().getCurrentUser();
        if (user != null) {
          // Sử dụng hàm update từ DatabaseService để đồng bộ
          await db.DatabaseService(
            uid: user.uid,
          ).updateAnalysisReport(widget.prescription.id, result);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Đã cập nhật phân tích vào lịch sử!"),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Lỗi phân tích: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra đơn có dữ liệu mắt không dựa trên sự tồn tại của trường eyeTest
    bool hasEyeTest = widget.prescription.eyeTest != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          "Chi tiết kết quả",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(),

            if (hasEyeTest) ...[
              const SizedBox(height: 24),
              _buildEyeTestSection(),
            ],

            if (widget.prescription.medicines.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildMedicineList(),
            ],

            if (_aiAnalysis != null && _aiAnalysis!.isNotEmpty)
              _buildFormattedAnalysis(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: (_aiAnalysis == null || _aiAnalysis!.isEmpty)
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _runDeepAnalysis,
              backgroundColor: kPrimaryColor,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                _isLoading ? "Đang phân tích..." : "Phân tích chuyên sâu",
              ),
            )
          : null,
    );
  }

  // --- FIX: Hiển thị thông số mắt thực tế từ Database ---
  Widget _buildEyeTestSection() {
    final eyeData = widget.prescription.eyeTest!;
    final rightEye = eyeData['right_eye'] ?? {};
    final leftEye = eyeData['left_eye'] ?? {};
    final pd = eyeData['pd']?.toString() ?? "-";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "👓 Thông số đơn kính",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              DataTable(
                columnSpacing: 15,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
                columns: const [
                  DataColumn(label: Text('Mắt')),
                  DataColumn(label: Text('Cầu')),
                  DataColumn(label: Text('Trụ')),
                  DataColumn(label: Text('Trục')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          "Phải (R)",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(rightEye['sph']?.toString() ?? "-")),
                      DataCell(Text(rightEye['cyl']?.toString() ?? "-")),
                      DataCell(Text(rightEye['axis']?.toString() ?? "-")),
                    ],
                  ),
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          "Trái (L)",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(leftEye['sph']?.toString() ?? "-")),
                      DataCell(Text(leftEye['cyl']?.toString() ?? "-")),
                      DataCell(Text(leftEye['axis']?.toString() ?? "-")),
                    ],
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.all(16.0), child: Divider()),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Khoảng cách đồng tử (PD):",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "$pd mm",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Row(
          children: [
            Icon(Icons.analytics_outlined, color: kPrimaryColor),
            SizedBox(width: 8),
            Text(
              "🔬 PHÂN TÍCH TỪ AI",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWarningBox(),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: MarkdownBody(
            data: _aiAnalysis!,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(
                color: kPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              p: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageHeader() => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      height: 220,
      width: double.infinity,
      color: Colors.black12,
      child: widget.prescription.imagePath.isNotEmpty
          ? Image.file(File(widget.prescription.imagePath), fit: BoxFit.cover)
          : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
    ),
  );

  Widget _buildInfoCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Column(
      children: [
        _infoRow(
          Icons.business,
          "Cơ sở khám bệnh",
          widget.prescription.hospitalName,
        ),
        const Divider(height: 30),
        _infoRow(Icons.event_note, "Ngày khám", widget.prescription.date),
        const Divider(height: 30),
        _infoRow(
          Icons.medical_information,
          "Chẩn đoán",
          widget.prescription.diagnose,
        ),
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20, color: kPrimaryColor),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildMedicineList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Toa thuốc chi tiết",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      ...widget.prescription.medicines
          .map(
            (m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: kPrimaryColor),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "SL: ${m.quantity} | ${m.usage}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ],
  );

  Widget _buildWarningBox() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.2)),
    ),
    child: const Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            "Phân tích chỉ mang tính chất tham khảo y khoa. Luôn tuân thủ chỉ định của chuyên gia.",
            style: TextStyle(
              fontSize: 11,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
