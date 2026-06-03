import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/app_auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color kDark = AppTheme.canvasDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kLight = AppTheme.iosLight;

    return Scaffold(
      backgroundColor: kDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Tạo tài khoản',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bắt đầu hành trình quản lý tài chính và du lịch cùng Miane',

                style: GoogleFonts.beVietnamPro(
                  color: kAzure.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              // Full Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Họ và tên',
                hint: 'Nguyễn Văn A',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'name@example.com',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: 'Mật khẩu',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              // Confirm Password Field
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                hint: '••••••••',
                icon: Icons.lock_clock_outlined,
                isPassword: true,
              ),
              const SizedBox(height: 32),
              // Register Button
              GestureDetector(
                onTap: () {
                  ref.read(appAuthProvider.notifier).registerFake();
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kAzure,
                    borderRadius: BorderRadius.circular(12), // rounded: md
                    boxShadow: [
                      BoxShadow(
                        color: kAzure.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Đăng ký',
                      style: GoogleFonts.beVietnamPro(
                        color: kLight,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kLight = AppTheme.iosLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: kLight.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kNavy,
            borderRadius: BorderRadius.circular(12), // rounded: md
            border: Border.all(
              color: kAzure.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.beVietnamPro(color: kLight, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.beVietnamPro(
                color: kLight.withValues(alpha: 0.3),
              ),
              prefixIcon: Icon(icon, color: kAzure.withValues(alpha: 0.6), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
