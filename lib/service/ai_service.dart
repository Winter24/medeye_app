import 'dart:convert';
import 'package:http/http.dart' as http;
import 'native_service.dart';

class SambaService {
  static final SambaService _instance = SambaService._internal();
  factory SambaService() => _instance;
  SambaService._internal();

  // Endpoint chuẩn của SambaNova Cloud
  final String _baseUrl = "https://api.sambanova.ai/v1/chat/completions";

  // Các model Nghi đã chọn từ danh sách
  final String _fastModel = "Meta-Llama-3.3-70B-Instruct";
  final String _smartModel = "Meta-Llama-3.3-70B-Instruct";

  void init() {
    print("🚀 SambaNova Service đã sẵn sàng.");
  }

  /// HÀM 1: Trích xuất JSON (Dùng model 8B siêu nhanh)
  Future<Map<String, dynamic>?> extractPrescriptionJson(
    String rawOcrText,
  ) async {
    final apiKey = NativeService.getApiKey();
    print(apiKey);
    final prompt =
        """
    Dưới đây là văn bản OCR từ đơn thuốc:
    ---
    $rawOcrText
    ---
    Hãy trích xuất thông tin theo định dạng JSON. 
    
    YÊU CẦU XỬ LÝ:
    1. Nếu là ĐƠN THUỐC: Trích xuất danh sách 'medicines' (brandname, quantity, usage).
    2. Nếu là ĐƠN KÍNH: Trích xuất thông tin vào trường 'eye_test' gồm:
       - 'right_eye' (mắt phải) & 'left_eye' (mắt trái): Mỗi bên gồm {sph: độ cầu, cyl: độ trụ, axis: trục, va: thị lực}.
       - 'pd' (khoảng cách đồng tử/KCĐT).
    3. Các trường chung luôn phải có: 
       - hospital_name (tên bệnh viện/phòng khám)
       - date (ngày khám)
       - diagnose (chẩn đoán)

    LƯU Ý: 
    - Nếu là đơn kính, 'diagnose' thường là Tật khúc xạ, Cận thị, hoặc Loạn thị.
    - Sửa lỗi chính tả thuật ngữ y tế (VD: 'KCĐT' -> 'PD').
    - Chỉ trả về duy nhất định dạng JSON, không kèm giải thích.

    CẤU TRÚC JSON MẪU:
    {
      "hospital_name": "...",
      "date": "...",
      "diagnose": "...",
      "medicines": [],
      "eye_test": {
        "right_eye": {"sph": "", "cyl": "", "axis": "", "va": ""},
        "left_eye": {"sph": "", "cyl": "", "axis": "", "va": ""},
        "pd": ""
      }
    }
    """;
    return await _callSamba(prompt, apiKey, model: _fastModel, isJson: true);
  }

  /// HÀM 2: Phân tích sâu (Dùng model 70B thông minh)
  Future<String?> analyzeDeeply(
    List<dynamic> medicines,
    String diagnose,
  ) async {
    final apiKey = NativeService.getApiKey();
    final prompt =
        """
Bạn là một chuyên gia y tế. Hãy phân tích đơn thuốc:
- Chẩn đoán: $diagnose
- Thuốc: ${jsonEncode(medicines)}

YÊU CẦU: Cấu trúc báo cáo theo các Mục 1, 2, 3 dùng dấu #. 
Cuối bài ghi: "Cảnh báo: Thông tin này chỉ mang tính tham khảo."
""";
    final result = await _callSamba(
      prompt,
      apiKey,
      model: _smartModel,
      isJson: false,
    );
    return result as String?;
  }

  /// HÀM LÕI GỌI API
  Future<dynamic> _callSamba(
    String prompt,
    String apiKey, {
    required String model,
    bool isJson = false,
  }) async {
    print("📡 [DEBUG] Đang gửi yêu cầu tới SambaNova...");
    print(
      "🔑 [DEBUG] API Key sử dụng: ${apiKey.isNotEmpty ? apiKey.substring(0, 5) + "..." : "TRỐNG"}",
    );

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              "Authorization": "Bearer $apiKey",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "model": model,
              "messages": [
                {
                  "role": "system",
                  "content":
                      "You are a medical assistant. Return ONLY JSON if requested.",
                },
                {"role": "user", "content": prompt},
              ],
              "stream":
                  false, // SambaNova cần set false để nhận toàn bộ nội dung một lần
              "temperature": 0.1,
            }),
          )
          .timeout(const Duration(seconds: 20));

      print("📬 [DEBUG] Phản hồi Server - Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String content = data['choices'][0]['message']['content'];

        if (isJson) {
          // Bóc tách JSON nếu model trả về trong khối Markdown ```json
          if (content.contains("```")) {
            content = content.split("```")[1].replaceFirst("json", "").trim();
          }
          return jsonDecode(content);
        }
        return content;
      } else {
        // Log lỗi chi tiết từ server (Ví dụ: 401 là sai Key)
        print("❌ [DEBUG] Server báo lỗi: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔥 [DEBUG] Lỗi kết nối hoặc thực thi: $e");
      return null;
    }
  }
}
