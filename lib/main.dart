import 'package:flutter/material.dart';
import 'package:medeye_app/screen/splash_screen.dart';
import 'package:medeye_app/screen/onboarding_screen.dart';
import 'package:medeye_app/screen/login_screen.dart';
import 'package:medeye_app/screen/register_screen.dart';
import 'package:medeye_app/screen/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medeye_app/service/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); //

  try {
    // Gọi hàm init() mà chúng ta vừa thêm vào ai_service.dart
    SambaService().init();
    print("✅ Cấu hình AI Service thành công");
  } catch (e) {
    print("❌ Lỗi khởi tạo AI Service: $e");
  }

  runApp(const MedEyeApp());
}

class MedEyeApp extends StatelessWidget {
  const MedEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedEye',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        // Màu tím chủ đạo đặc trưng của dự án Medeye
        primaryColor: const Color(0xFFB58BFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB58BFF),
          primary: const Color(0xFFB58BFF),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
