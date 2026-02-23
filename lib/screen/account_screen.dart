import 'package:flutter/material.dart';

// --- Constants ---
const Color kPrimaryColor = Color(0xFFB58BFF);
const Color kPrimaryLightColor = Color(0xFFE6DFFD);

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const avatarRadius = 50.0;

    // The vertical position where the purple header ends.
    final double headerBoundary = screenHeight * 0.22;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: Stack(
        children: [
          // Layer 1: The purple header at the top
          Container(
            height: headerBoundary,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE6DFFD), Color(0xFFD0BFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    'Tài khoản',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Layer 2: The scrollable white content area
          Padding(
            padding: EdgeInsets.only(top: headerBoundary),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35.0)),
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, avatarRadius + 24, 24, 24),
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    text: 'Hồ sơ cá nhân',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.shopping_cart_outlined,
                    text: 'Đơn hàng',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    text: 'Các câu hỏi thường gặp',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    text: 'Về chúng tôi',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    text: 'Đăng xuất',
                    isLogout: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'Phiên bản 1.1.1',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Layer 3: The Avatar, positioned on top of the other layers
          Positioned(
            top: headerBoundary - avatarRadius,
            left: screenWidth / 2 - avatarRadius,
            child: _buildAvatar(avatarRadius),
          ),
        ],
      ),
    );
  }

  /// Builds the Circle Avatar and its edit button
  Widget _buildAvatar(double radius) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: const NetworkImage(
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=761&q=80',
          ),
        ),
        Positioned(
          bottom: 2,
          right: -4,
          child: Container(
            height: 35,
            width: 35,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  /// Builds a reusable list tile for the menu items
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final Color iconColor = isLogout ? Colors.red : kPrimaryColor;
    final Color iconBackgroundColor = isLogout
        ? const Color(0xFFFEEEEE)
        : kPrimaryLightColor;
    final Color textColor = isLogout ? Colors.red : Colors.black87;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }
}
