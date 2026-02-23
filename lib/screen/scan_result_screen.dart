import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medeye_app/service/ai_service.dart'; // Import GeminiService của bạn

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
  String _hospitalName = "Đang phân tích...";
  String _date = "...";
  String _diagnose = "Đang chẩn đoán...";
  bool _isAiLoading = true; // Trạng thái chờ Gemini xử lý

  @override
  void initState() {
    super.initState();
    _processWithGemini();
  }

  // Gửi rawOcrText cho Gemini xử lý prompt trích xuất JSON
  Future<void> _processWithGemini() async {
    try {
      final result = await GeminiService().extractPrescriptionData(
        widget.rawOcrText,
      );

      if (result != null) {
        setState(() {
          _hospitalName = result['hospital_name']?.toString() ?? "Không rõ";
          _date =
              result['date']?.toString() ??
              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
          _diagnose = result['diagnose']?.toString() ?? "Không có thông tin";

          final List<dynamic> medsJson = result['medicines'] ?? [];
          _medicines = medsJson
              .map(
                (m) => Medicine(
                  name: m['brandname']?.toString() ?? "Thuốc không tên",
                  quantity: m['quantity']?.toString() ?? "Theo đơn",
                  usage: m['usage']?.toString() ?? "Chưa rõ cách dùng",
                ),
              )
              .toList();

          _isAiLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hospitalName = "Lỗi phân tích AI";
        _isAiLoading = false;
      });
      print("AI Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Đơn thuốc của bạn',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isAiLoading
          ? _buildLoadingState() // Hiển thị khi AI đang chạy
          : _buildResultContent(), // Hiển thị khi đã có JSON
    );
  }

  // Widget hiển thị khi AI đang làm việc
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: kPrimaryColor),
          const SizedBox(height: 20),
          Text(
            "Medeye đang trích xuất dữ liệu...",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Vui lòng đợi trong giây lát",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị kết quả cuối cùng
  Widget _buildResultContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. Ảnh đơn thuốc
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
              image: DecorationImage(
                image: FileImage(File(widget.imagePath)),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Nút hành động
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {}, // Lưu Firebase tại đây
              icon: const Icon(Icons.save_outlined, color: Colors.black),
              label: const Text(
                "Lưu vào lịch sử",
                style: TextStyle(color: Colors.black),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Thông tin chung
          _buildInfoCard(),
          const SizedBox(height: 20),

          // 4. Danh sách thuốc
          _buildMedicineListCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow("Ngày khám:", _date),
          const Divider(),
          _buildInfoRow("Nơi khám:", _hospitalName),
          const Divider(),
          _buildInfoRow("Chẩn đoán:", _diagnose),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineListCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Danh sách thuốc:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _medicines.isEmpty
              ? const Text("Không tìm thấy thông tin thuốc")
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _medicines.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 30),
                  itemBuilder: (context, index) {
                    final medicine = _medicines[index];
                    return _buildMedicineItem(index + 1, medicine);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(int index, Medicine medicine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$index. ${medicine.name}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: [
              _rowMed("Số lượng:", medicine.quantity),
              const SizedBox(height: 4),
              _rowMed("Cách dùng:", medicine.usage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowMed(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
