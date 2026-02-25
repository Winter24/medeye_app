import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:medeye_app/service/ai_service.dart'; // Đảm bảo tên file chứa SambaService đúng
import 'package:medeye_app/service/auth_service.dart';
import 'package:medeye_app/service/database_service.dart' as db;

// Màu sắc chủ đạo của dự án Medeye
const Color kPrimaryColor = Color(0xFFB58BFF);

class Medicine {
  final String name;
  final String quantity;
  final String usage;
  Medicine({required this.name, required this.quantity, required this.usage});
}

class ScanResultScreen extends StatefulWidget {
  final String imagePath;
  final String rawOcrText;

  const ScanResultScreen({
    super.key,
    required this.imagePath,
    required this.rawOcrText,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  List<Medicine> _medicines = [];
  String _hospitalName = "Đang trích xuất...";
  String _date = "...";
  String _diagnose = "Đang xử lý...";
  String? _aiAnalysis;

  bool _isExtracting = true;
  bool _isDeepAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _extractInitialData();
  }

  Future<void> _extractInitialData() async {
    try {
      final result = await SambaService().extractPrescriptionJson(
        widget.rawOcrText,
      );

      if (result != null) {
        setState(() {
          _hospitalName = result['hospital_name'] ?? "Không rõ";
          _date = result['date'] ?? "";
          _diagnose = result['diagnose'] ?? "";

          final List<dynamic> medsJson = result['medicines'] ?? [];
          _medicines = medsJson
              .map(
                (m) => Medicine(
                  name: m['brandname']?.toString() ?? "Thuốc không tên",
                  quantity: m['quantity']?.toString() ?? "1",
                  usage: m['usage']?.toString() ?? "Theo chỉ định",
                ),
              )
              .toList();
          _isExtracting = false;
        });
      }
    } catch (e) {
      debugPrint("❌ [LỖI TRÍCH XUẤT]: $e");
      setState(() {
        _hospitalName = "Lỗi trích xuất";
        _isExtracting = false;
      });
    }
  }

  Future<void> _runDeepAnalysis() async {
    if (_diagnose == "Đang xử lý...") return;

    setState(() => _isDeepAnalyzing = true);
    try {
      final medsData = _medicines
          .map(
            (m) => {
              'brandname': m.name,
              'quantity': m.quantity,
              'usage': m.usage,
            },
          )
          .toList();

      final report = await SambaService().analyzeDeeply(medsData, _diagnose);

      if (report != null) {
        setState(() {
          _aiAnalysis = report;
          _isDeepAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() => _isDeepAnalyzing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi phân tích sâu từ AI")));
    }
  }

  Future<void> _saveToHistory() async {
    final user = AuthService().getCurrentUser();
    if (user == null) return;

    final prescription = db.Prescription(
      id: '',
      hospitalName: _hospitalName,
      date: _date,
      diagnose: _diagnose,
      medicines: _medicines
          .map(
            (m) =>
                db.Medicine(name: m.name, quantity: m.quantity, usage: m.usage),
          )
          .toList(),
      imagePath: widget.imagePath,
      createdAt: DateTime.now(),
      analysisReport: _aiAnalysis,
    );

    try {
      await db.DatabaseService(uid: user.uid).savePrescription(prescription);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Đã lưu vào lịch sử!")));
      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ [LỖI LƯU TRỮ]: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Kết quả Medeye AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isExtracting ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: kPrimaryColor),
        SizedBox(height: 20),
        Text(
          "SambaNova RDU đang xử lý dữ liệu...",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagePreview(),
          const SizedBox(height: 16),
          _buildSaveButton(),
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildMedicineList(),
          const SizedBox(height: 24),

          if (_aiAnalysis == null)
            _buildDeepAnalysisButton()
          else
            _buildFormattedAnalysis(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildFormattedAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "🔬 Phân tích chuyên sâu",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        _buildWarningBox(),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
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
              p: const TextStyle(fontSize: 14, height: 1.5),
              listBullet: const TextStyle(color: kPrimaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeepAnalysisButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isDeepAnalyzing ? null : _runDeepAnalysis,
        icon: _isDeepAnalyzing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kPrimaryColor,
                ),
              )
            : const Icon(Icons.auto_awesome, color: kPrimaryColor),
        label: Text(
          _isDeepAnalyzing ? "ĐANG PHÂN TÍCH..." : "PHÂN TÍCH TƯƠNG TÁC THUỐC",
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kPrimaryColor, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.file(
      File(widget.imagePath),
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  );

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
      onPressed: _saveToHistory,
      icon: const Icon(Icons.save_alt, color: Colors.white),
      label: const Text(
        "LƯU ĐƠN THUỐC",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
    ),
  );

  Widget _buildInfoCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: [
        _infoRow("Ngày:", _date),
        const Divider(),
        _infoRow("Bệnh viện:", _hospitalName),
        const Divider(),
        _infoRow("Chẩn đoán:", _diagnose),
      ],
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _buildMedicineList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "💊 Toa thuốc",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const SizedBox(height: 12),
      ..._medicines
          .map(
            (m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.medication, color: kPrimaryColor),
                title: Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("SL: ${m.quantity} | ${m.usage}"),
              ),
            ),
          )
          .toList(),
    ],
  );

  Widget _buildWarningBox() => Container(
    padding: const EdgeInsets.all(12),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            "Mọi thông tin chỉ mang tính chất tham khảo. Tuân thủ chỉ định của bác sĩ.",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
