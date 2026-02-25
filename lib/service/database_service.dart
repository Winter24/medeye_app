import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String name;
  final String quantity;
  final String usage;

  Medicine({required this.name, required this.quantity, required this.usage});

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'usage': usage,
  };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
    name: map['name'] ?? '',
    quantity: map['quantity'] ?? '',
    usage: map['usage'] ?? '',
  );
}

class Prescription {
  final String id;
  final String hospitalName;
  final String date;
  final String diagnose;
  final List<Medicine> medicines;
  final String imagePath;
  final DateTime createdAt;
  final String? analysisReport;

  // --- THÊM TRƯỜNG EYE TEST ĐỂ LƯU THÔNG SỐ MẮT ---
  final Map<String, dynamic>? eyeTest;

  Prescription({
    required this.id,
    required this.hospitalName,
    required this.date,
    required this.diagnose,
    required this.medicines,
    required this.imagePath,
    required this.createdAt,
    this.analysisReport,
    this.eyeTest, // Constructor mới nhận thêm eyeTest
  });

  Map<String, dynamic> toMap() => {
    'hospitalName': hospitalName,
    'date': date,
    'diagnose': diagnose,
    'medicines': medicines.map((m) => m.toMap()).toList(),
    'imagePath': imagePath,
    'createdAt': createdAt,
    'analysisReport': analysisReport,
    'eyeTest': eyeTest, // Lưu Map thông số mắt lên Firestore
  };

  factory Prescription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Prescription(
      id: doc.id,
      hospitalName: data['hospitalName'] ?? '',
      date: data['date'] ?? '',
      diagnose: data['diagnose'] ?? '',
      medicines: (data['medicines'] as List? ?? [])
          .map((m) => Medicine.fromMap(m as Map<String, dynamic>))
          .toList(),
      imagePath: data['imagePath'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      analysisReport: data['analysisReport'],
      eyeTest:
          data['eyeTest']
              as Map<String, dynamic>?, // Đọc dữ liệu mắt từ Firestore
    );
  }
}

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  /// Lưu đơn khám (bao gồm cả đơn thuốc và đơn kính)
  Future<void> savePrescription(Prescription p) async {
    if (uid == null) return;
    await userCollection.doc(uid).collection('prescriptions').add(p.toMap());
  }

  /// Cập nhật báo cáo phân tích AI vào tài liệu đã tồn tại
  Future<void> updateAnalysisReport(
    String prescriptionId,
    String report,
  ) async {
    if (uid == null) return;
    await userCollection
        .doc(uid)
        .collection('prescriptions')
        .doc(prescriptionId)
        .update({'analysisReport': report});
  }

  Future<void> createUserData(String email, String phone) async {
    if (uid == null) return;
    await userCollection.doc(uid).set({
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Prescription>> get prescriptions {
    return userCollection
        .doc(uid)
        .collection('prescriptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Prescription.fromFirestore(doc)).toList(),
        );
  }
}
