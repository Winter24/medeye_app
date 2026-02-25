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
  final String? analysisReport; // Thêm trường lưu trữ báo cáo

  Prescription({
    required this.id,
    required this.hospitalName,
    required this.date,
    required this.diagnose,
    required this.medicines,
    required this.imagePath,
    required this.createdAt,
    this.analysisReport, // PHẢI CÓ DÒNG NÀY ĐỂ HẾT LỖI
  });

  Map<String, dynamic> toMap() => {
    'hospitalName': hospitalName,
    'date': date,
    'diagnose': diagnose,
    'medicines': medicines.map((m) => m.toMap()).toList(),
    'imagePath': imagePath,
    'createdAt': createdAt,
    'analysisReport': analysisReport,
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
      analysisReport: data['analysisReport'], // Đọc dữ liệu từ Cache
    );
  }
}

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  Future<void> savePrescription(Prescription p) async {
    if (uid == null) return;
    // Dùng await để đảm bảo hàm trả về Future<void>
    await userCollection.doc(uid).collection('prescriptions').add(p.toMap());
  }

  // Giữ lại hàm createUserData để không lỗi Register Screen
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
