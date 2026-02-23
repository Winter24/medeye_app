import 'package:flutter/material.dart';
import 'package:medeye_app/screen/splash_screen.dart';
import 'package:medeye_app/screen/onboarding_screen.dart';
import 'package:medeye_app/screen/login_screen.dart';
import 'package:medeye_app/screen/register_screen.dart';
import 'package:medeye_app/screen/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medeye_app/service/ai_service.dart';
// import 'package:medeye_app/service/prescription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  try {
    GeminiService().init();
    print("✅ Gemini AI đã cấu hình thành công với Native Key");
  } catch (e) {
    print("❌ Lỗi khởi tạo Gemini AI: $e");
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
        primaryColor: const Color(0xFFB58BFF),
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
