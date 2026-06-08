import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/app_auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                'Chào mừng trở lại',
                style: GoogleFonts.inter(
                  color: kLight,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập để tiếp tục quản lý các chuyến đi của bạn',
                style: GoogleFonts.beVietnamPro(
                  color: kAzure.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'name@example.com',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: 'Mật khẩu',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Quên mật khẩu?',
                    style: GoogleFonts.beVietnamPro(
                      color: kAzure,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Login Button
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng điền đầy đủ email và mật khẩu'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        try {
                          await ref.read(appAuthProvider.notifier).login(email, password);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          setState(() => _isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đăng nhập thất bại: ${e.toString().replaceAll('ApiException: ', '')}'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kAzure,
                    borderRadius: BorderRadius.circular(12), // rounded: md
                    boxShadow: [
                      BoxShadow(
                        color: kAzure.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: kLight,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Đăng nhập',
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
            color: kLight.withOpacity(0.7),
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
              color: kAzure.withOpacity(0.25),
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
                color: kLight.withOpacity(0.3),
              ),
              prefixIcon: Icon(icon, color: kAzure.withOpacity(0.6), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
