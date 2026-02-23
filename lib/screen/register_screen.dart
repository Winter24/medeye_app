import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:medeye_app/service/auth_service.dart';
// --- FIX 1: Import the DatabaseService ---
import 'package:medeye_app/service/database_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- State and Controllers (No changes here) ---
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  String _errorMessage = '';
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _termsAccepted = false;

  // --- Dispose Controllers (No changes here) ---
  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Registration Logic ---
  // --- FIX 2: This entire method is updated ---
  Future<void> _register() async {
    // --- 1. Client-side Validation (No changes here) ---
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp.');
      return;
    }
    if (!_termsAccepted) {
      setState(
        () => _errorMessage = 'Bạn phải đồng ý với điều khoản và chính sách.',
      );
      return;
    }
    if (_isLoading) return;

    // --- 2. Start Loading and Call Services ---
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Step A: Call AuthService and get the created User object back.
      // (This assumes your AuthService method was updated to return `Future<User?>`)
      User? user = await _authService.registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Step B: Check if user creation was successful.
      if (user != null) {
        // Step C: If successful, create a document in Firestore for this user.
        String phone = _phoneController.text.trim();
        await DatabaseService(
          uid: user.uid,
        ).createUserData(_emailController.text.trim(), phone);

        // Step D: Only navigate to home screen after everything is successful.
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      // Error handling (No changes here, this is good)
      switch (e.code) {
        case 'weak-password':
          _errorMessage = 'Mật khẩu cung cấp quá yếu.';
          break;
        case 'email-already-in-use':
          _errorMessage = 'Tài khoản đã tồn tại cho email này.';
          break;
        case 'invalid-email':
          _errorMessage = 'Địa chỉ email không hợp lệ.';
          break;
        default:
          _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      }
    } catch (e) {
      // Generic error handling
      _errorMessage = "Đã xảy ra lỗi không mong muốn.";
    }

    // --- 3. Stop Loading ---
    setState(() {
      _isLoading = false;
    });
  }

  // --- Build UI (No changes from here down) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                const Text(
                  'Tạo tài khoản',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // --- Phone Field ---
                _buildLabel('Số điện thoại', isRequired: true),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    hint: 'Nhập số điện thoại của bạn',
                  ),
                ),
                const SizedBox(height: 20),

                // --- Email Field ---
                _buildLabel('Email'),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: 'Ví dụ: NguyenVanA@gmail.com',
                  ),
                ),
                const SizedBox(height: 20),

                // --- Password Field ---
                _buildLabel('Mật khẩu', isRequired: true),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _inputDecoration(hint: '••••••••••').copyWith(
                    suffixIcon: _visibilityIcon(
                      isVisible: _isPasswordVisible,
                      onTap: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Confirm Password Field ---
                _buildLabel('Xác nhận mật khẩu', isRequired: true),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: _inputDecoration(hint: '••••••••••').copyWith(
                    suffixIcon: _visibilityIcon(
                      isVisible: _isConfirmPasswordVisible,
                      onTap: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Terms and Conditions ---
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _termsAccepted,
                        onChanged: (value) =>
                            setState(() => _termsAccepted = value ?? false),
                        activeColor: const Color(0xFFB58BFF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          children: [
                            const TextSpan(text: 'Tôi hiểu và đồng ý với '),
                            TextSpan(
                              text: 'điều khoản & chính sách',
                              style: const TextStyle(color: Color(0xFFB58BFF)),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  /* TODO: Show Terms and Conditions */
                                },
                            ),
                            const TextSpan(text: ' này.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Error Message ---
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                // --- Register Button ---
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _gradientButton(text: 'Đăng ký', onPressed: _register),
                ),
                const SizedBox(height: 30),

                // --- Divider ---
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'hoặc đăng ký bằng',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Social Login Buttons ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(
                      assetName: 'lib/assets/images/google_logo.png',
                      onTap: () {
                        /*TODO: Google Login*/
                      },
                    ),
                    const SizedBox(width: 20),
                    _socialButton(
                      assetName: 'lib/assets/images/facebook_logo.png',
                      onTap: () {
                        /*TODO: Facebook Login*/
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- Login Link ---
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                        children: [
                          TextSpan(text: 'Bạn đã có tài khoản? '),
                          TextSpan(
                            text: 'Đăng nhập',
                            style: TextStyle(
                              color: Color(0xFFB58BFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (No changes here) ---
  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          children: [
            TextSpan(text: text),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _visibilityIcon({
    required bool isVisible,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.grey,
      ),
      onPressed: onTap,
    );
  }

  Widget _gradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFC9A7FF), Color(0xFFA36DFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB58BFF).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String assetName,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Image.asset(assetName, height: 28, width: 28),
      ),
    );
  }
}
