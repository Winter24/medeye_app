import 'package:cloud_firestore/cloud_firestore.dart';

// --- MODELS ---

class Medicine {
  final String name;
  final String quantity;
  final String usage;

  Medicine({required this.name, required this.quantity, required this.usage});

  // Chuyển sang Map để lưu Firebase
  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity, 'usage': usage};
  }

  // Chuyển từ Firebase về đối tượng Medicine
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '',
      usage: map['usage'] ?? '',
    );
  }
}

class Prescription {
  final String id;
  final String hospitalName;
  final String date;
  final String diagnose;
  final List<Medicine> medicines;
  final String imagePath;
  final DateTime createdAt;

  Prescription({
    required this.id,
    required this.hospitalName,
    required this.date,
    required this.diagnose,
    required this.medicines,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'hospitalName': hospitalName,
      'date': date,
      'diagnose': diagnose,
      'medicines': medicines
          .map((m) => m.toMap())
          .toList(), // Chuyển list object sang list map
      'imagePath': imagePath,
      'createdAt':
          FieldValue.serverTimestamp(), // Dùng timestamp của server Firebase
    };
  }

  // Chuyển từ Firebase Snapshot về đối tượng Prescription
  factory Prescription.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Prescription(
      id: doc.id,
      hospitalName: data['hospitalName'] ?? '',
      date: data['date'] ?? '',
      diagnose: data['diagnose'] ?? '',
      medicines: (data['medicines'] as List)
          .map((m) => Medicine.fromMap(m as Map<String, dynamic>))
          .toList(),
      imagePath: data['imagePath'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

// --- DATABASE SERVICE ---

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Tham chiếu đến collection 'users'
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  // 1. Tạo thông tin người dùng ban đầu
  Future<void> createUserData(String email, String phone) async {
    return await userCollection.doc(uid).set({
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. LƯU ĐƠN THUỐC MỚI (Vào sub-collection của user đó)
  Future<void> savePrescription(Prescription p) async {
    try {
      if (uid == null) return;

      // Đường dẫn: users/{uid}/prescriptions/ (tự động tạo ID ngẫu nhiên)
      await userCollection.doc(uid).collection('prescriptions').add(p.toMap());
    } catch (e) {
      print("Lỗi khi lưu đơn thuốc: $e");
      rethrow;
    }
  }

  // 3. LẤY DANH SÁCH ĐƠN THUỐC (Sử dụng Stream để cập nhật realtime)
  Stream<List<Prescription>> get prescriptions {
    return userCollection
        .doc(uid)
        .collection('prescriptions')
        .orderBy('createdAt', descending: true) // Mới nhất lên đầu
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Prescription.fromFirestore(doc))
              .toList();
        });
  }
}
