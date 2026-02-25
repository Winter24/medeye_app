import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medeye_app/service/database_service.dart'
    as db; // Alias để tránh trùng tên class
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
    // Lấy báo cáo đã có từ lịch sử (nếu có)
    _aiAnalysis = widget.prescription.analysisReport;
  }

  /// Gọi SambaNova 70B để phân tích chuyên sâu
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

        // Cập nhật kết quả vào Firestore
        final user = AuthService().getCurrentUser();
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('prescriptions')
              .doc(widget.prescription.id)
              .update({'analysisReport': result});

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          "Chi tiết đơn thuốc",
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
            const SizedBox(height: 24),
            _buildMedicineList(),

            // HIỂN THỊ BÁO CÁO MỚI
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
                _isLoading ? "Đang phân tích..." : "Phân tích đơn thuốc",
              ),
            )
          : null,
    );
  }

  // --- UI COMPONENTS SỬA ĐỔI ---

  Widget _buildFormattedAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          "🔬 PHÂN TÍCH CHUYÊN SÂU",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kPrimaryColor,
          ),
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
              h2: const TextStyle(
                color: kPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              p: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
              listBullet: const TextStyle(color: kPrimaryColor),
              blockSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }

  // --- CÁC UI GIỮ NGUYÊN HOẶC TINH CHỈNH NHẸ ---

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
        _infoRow(Icons.business, "Nơi khám", widget.prescription.hospitalName),
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
            "Tham khảo y khoa chuyên sâu từ AI. Cần tuân thủ chỉ định của bác sĩ.",
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
