import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'native_service.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  late final GenerativeModel _model;

  void init() {
    final apiKey = NativeService.getApiKey();

    if (apiKey.length > 5) {
      print("Debug API Key prefix: ${apiKey}");
    } else {
      print("Debug API Key lỗi: $apiKey");
    }

    _model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);
  }

  Future<Map<String, dynamic>?> extractPrescriptionData(
    String rawOcrText,
  ) async {
    final prompt =
        """
    Dưới đây là văn bản OCR từ đơn thuốc:
    ---
    $rawOcrText
    ---
    Hãy trích xuất thông tin theo định dạng JSON gồm các trường: 
    - hospital_name (tên bệnh viện)
    - date (ngày khám)
    - diagnose (chẩn đoán)
    - medicines (danh sách thuốc, mỗi thuốc gồm: brandname, quantity, usage).

    Nếu từ nào sai chính tả hãy sửa lại cho đúng thuật ngữ y tế. 
    Lưu ý: Chỉ trả về duy nhất định dạng JSON, không kèm giải thích. Vitamin cũng tính vào medicines 
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      String? text = response.text;
      if (text == null) return null;

      if (text.contains("```json")) {
        text = text.split("```json")[1].split("```")[0].trim();
      } else if (text.contains("```")) {
        text = text.split("```")[1].split("```")[0].trim();
      }

      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      print("Lỗi Gemini: $e");
      return null;
    }
  }
}
