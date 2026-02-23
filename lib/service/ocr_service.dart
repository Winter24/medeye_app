import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv2;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class OnnxPipeline {
  static final OnnxPipeline _instance = OnnxPipeline._internal();
  factory OnnxPipeline() => _instance;
  OnnxPipeline._internal();

  OrtSession? _sessionSegment;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  bool isLoaded = false;

  Future<void> init() async {
    if (isLoaded) return;
    try {
      OrtEnv.instance.init();
      final opts = OrtSessionOptions()..setIntraOpNumThreads(4);

      _sessionSegment = await _createSession(
        'lib/assets/models/segmentator.onnx',
        opts,
      );

      isLoaded = true;
      print("✅ OCR ready");
    } catch (e) {
      print("❌ OCR Init Error: $e");
    }
  }

  Future<OrtSession> _createSession(String path, OrtSessionOptions opts) async {
    final raw = await rootBundle.load(path);
    return OrtSession.fromBuffer(raw.buffer.asUint8List(), opts);
  }

  Future<String> runPipeline(String imagePath) async {
    if (!isLoaded) await init();

    cv2.Mat originalImg = cv2.imread(imagePath);
    if (originalImg.isEmpty) return "Không thể đọc ảnh";

    cv2.Mat? alignedDoc;
    File? tempFile;

    try {
      alignedDoc = await _processDocScanner(originalImg);

      tempFile = await _saveMatToTemp(alignedDoc);
      final inputImage = InputImage.fromFile(tempFile);

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      if (recognizedText.text.trim().isEmpty) {
        return "Không tìm thấy nội dung văn bản trong ảnh.";
      }

      return recognizedText.text;
    } catch (e) {
      return "Lỗi xử lý OCR: $e";
    } finally {
      // GIẢI PHÓNG BỘ NHỚ
      originalImg.release();
      alignedDoc?.release();
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<File> _saveMatToTemp(cv2.Mat mat) async {
    final (success, bytes) = cv2.imencode(".jpg", mat);
    if (!success) throw Exception("Lỗi mã hóa ảnh OpenCV");

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/ocr_process_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    return await file.writeAsBytes(bytes);
  }

  Future<cv2.Mat> _processDocScanner(cv2.Mat src) async {
    cv2.Mat resized = cv2.resize(src, (320, 320));
    final input = _preprocessGeneric(resized, 320, 320);

    final outputs = _sessionSegment!.run(OrtRunOptions(), {'input': input});
    final mask = _getMaskFromOutput(outputs[0]!.value, 320, 320);

    resized.release();

    final (contours, _) = cv2.findContours(
      mask,
      cv2.RETR_EXTERNAL,
      cv2.CHAIN_APPROX_SIMPLE,
    );
    mask.release();

    if (contours.isEmpty) return src.clone();

    var mainContour = contours.first;
    for (var c in contours) {
      if (cv2.contourArea(c) > cv2.contourArea(mainContour)) mainContour = c;
    }

    final approx = cv2.approxPolyDP(
      mainContour,
      0.02 * cv2.arcLength(mainContour, true),
      true,
    );

    if (approx.length == 4) {
      double rx = src.cols / 320.0;
      double ry = src.rows / 320.0;

      List<cv2.Point> srcPts = _orderPoints(approx, rx, ry);

      double width = _dist(srcPts[0], srcPts[1]);
      double height = _dist(srcPts[0], srcPts[3]);

      final dstPts = cv2.VecPoint.fromList([
        cv2.Point(0, 0),
        cv2.Point(width.toInt(), 0),
        cv2.Point(width.toInt(), height.toInt()),
        cv2.Point(0, height.toInt()),
      ]);

      final m = cv2.getPerspectiveTransform(
        cv2.VecPoint.fromList(srcPts),
        dstPts,
      );
      final warped = cv2.warpPerspective(src, m, (
        width.toInt(),
        height.toInt(),
      ));

      m.release();
      return warped;
    }

    return src.clone();
  }

  OrtValueTensor _preprocessGeneric(cv2.Mat img, int h, int w) {
    cv2.Mat rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB);
    Float32List data = Float32List(3 * h * w);
    Uint8List bytes = rgb.data;

    for (int c = 0; c < 3; c++) {
      for (int i = 0; i < h * w; i++) {
        data[c * h * w + i] = bytes[i * 3 + c] / 255.0;
      }
    }
    rgb.release();
    return OrtValueTensor.createTensorWithDataList(data, [1, 3, h, w]);
  }

  cv2.Mat _getMaskFromOutput(dynamic val, int h, int w) {
    final flatList = (val as List)
        .expand(
          (e) =>
              (e as List).expand((e) => (e as List).expand((e) => e as List)),
        )
        .cast<double>()
        .toList();

    Uint8List bytes = Uint8List(h * w);
    for (int i = 0; i < flatList.length; i++) {
      bytes[i] = flatList[i] > 0.5 ? 255 : 0;
    }
    return cv2.Mat.fromList(h, w, cv2.MatType.CV_8UC1, bytes);
  }

  List<cv2.Point> _orderPoints(cv2.VecPoint approx, double rx, double ry) {
    List<Point<double>> pts = [];
    for (int i = 0; i < 4; i++) {
      final p = approx.elementAt(i);
      pts.add(Point(p.x * rx, p.y * ry));
    }

    // Sắp xếp tọa độ: top-left, top-right, bottom-right, bottom-left
    pts.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    Point<double> tl = pts[0];
    Point<double> br = pts[3];

    List<Point<double>> remaining = [pts[1], pts[2]];
    remaining.sort((a, b) => (a.y - a.x).compareTo(b.y - b.x));
    Point<double> tr = remaining[0];
    Point<double> bl = remaining[1];

    return [
      cv2.Point(tl.x.toInt(), tl.y.toInt()),
      cv2.Point(tr.x.toInt(), tr.y.toInt()),
      cv2.Point(br.x.toInt(), br.y.toInt()),
      cv2.Point(bl.x.toInt(), bl.y.toInt()),
    ];
  }

  double _dist(cv2.Point p1, cv2.Point p2) =>
      sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));

  void dispose() {
    _textRecognizer.close();
    _sessionSegment?.release();
    OrtEnv.instance.release();
  }
}
