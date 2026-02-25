import 'package:flutter/material.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dịch vụ y tế")),
      body: ListView(
        // Xóa 'const' ở đây
        children: const [
          ListTile(
            leading: Icon(Icons.local_hospital),
            title: Text("Đặt lịch khám"),
          ),
          ListTile(
            leading: Icon(
              Icons.chat,
            ), // Lưu ý: nên dùng 'chat' (viết thường) thay vì 'Chat'
            title: Text("Tư vấn bác sĩ"),
          ),
        ],
      ),
    );
  }
}
