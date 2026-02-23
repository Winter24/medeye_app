import 'package:flutter/material.dart';
// import 'package:medeye_app/screen/home_screen.dart';
import 'package:medeye_app/screen/login_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() => isLastPage = index == 2);
          },
          children: const [
            OnboardingPage(
              title: "Snap",
              description:
                  "Không cần giữ nhiều giấy tờ. Chỉ cần chụp bằng điện thoại, mọi thông tin sẽ được ghi lại.",
              icon: Icons.camera_alt_outlined,
            ),
            OnboardingPage(
              title: "Save",
              description:
                  "Giấy khám của bạn sẽ được lưu trong ứng dụng. Không lo thất lạc, luôn có sẵn khi cần.",
              icon: Icons.download_outlined,
            ),
            OnboardingPage(
              title: "See",
              description:
                  "Xem lại toàn bộ lịch sử khám mắt của bạn. Theo dõi sự thay đổi thị lực qua từng lần khám.",
              icon: Icons.visibility_outlined,
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SmoothPageIndicator(
              controller: _controller,
              count: 3,
              effect: const WormEffect(
                dotColor: Colors.grey,
                activeDotColor: AppColors.primary,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (isLastPage) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeIn,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isLastPage ? 'Bắt đầu' : 'Tiếp theo'),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 100, color: AppColors.primary),
        const SizedBox(height: 30),
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            description,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
