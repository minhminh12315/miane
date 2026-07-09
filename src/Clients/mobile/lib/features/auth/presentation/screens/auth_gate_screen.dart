import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/app_auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotate;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _subFade;
  late final Animation<Offset> _subSlide;
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Không lấy được Google ID Token.');
      }

      await ref.read(appAuthProvider.notifier).loginWithGoogle(idToken);
    } catch (e) {
      if (context.mounted) {
        _showMockLoginOptions(e.toString());
      }
    } finally {
      if (context.mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMockLoginOptions(String originalError) {
    final emailController = TextEditingController(text: 'miane.test@gmail.com');
    bool isMockLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.iosLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.build_circle_outlined,
                          color: AppTheme.iosGold,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Chế độ Phát triển / Thử nghiệm',
                          style: GoogleFonts.inter(
                            color: AppTheme.iosLight,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Google Sign-In trên thiết bị này chưa được cấu hình Client ID. Bạn có muốn sử dụng tài khoản thử nghiệm để tiếp tục không?',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.iosLight.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lỗi chi tiết: $originalError',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.redAccent.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nhập Email thử nghiệm:',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.iosLight.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.canvasDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.iosBlue.withOpacity(0.4),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: emailController,
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.iosLight,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'user@example.com',
                          hintStyle: GoogleFonts.beVietnamPro(
                            color: AppTheme.iosLight.withOpacity(0.3),
                          ),
                          prefixIcon: const Icon(
                            Icons.alternate_email,
                            color: AppTheme.iosBlue,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Hủy',
                              style: GoogleFonts.beVietnamPro(
                                color: AppTheme.iosLight.withOpacity(0.6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: isMockLoading
                                ? null
                                : () async {
                                    final email = emailController.text.trim();
                                    if (email.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Vui lòng nhập email hợp lệ'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }
                                    setModalState(() => isMockLoading = true);
                                    try {
                                      final mockToken = 'mock_google_token_$email';
                                      await ref.read(appAuthProvider.notifier).loginWithGoogle(mockToken);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (err) {
                                      setModalState(() => isMockLoading = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Thử nghiệm thất bại: $err'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.iosBlue,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: isMockLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppTheme.iosLight,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Đăng nhập Mock',
                                        style: GoogleFonts.beVietnamPro(
                                          color: AppTheme.iosLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Elastic spring scale-up for the logo circle
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    // Subtle rotate/spin for the inner sync icon
    _logoRotate = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
    );

    // Staggered slide/fade for the main "Miane" text
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    ));

    // Staggered slide/fade for the subtitle
    _subFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    _subSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    ));

    // Trigger the animation on load
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Styling constants matching DESIGN.md
    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kGold = AppTheme.iosGold;
    const Color kLight = AppTheme.iosLight;

    return Scaffold(
      backgroundColor: kDark,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kAzure.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kNavy.withOpacity(0.2),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo/Header Area with elastic spring animation
                  ScaleTransition(
                    scale: _logoScale,
                    child: RotationTransition(
                      turns: _logoRotate,
                      child: Hero(
                        tag: 'app-logo',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [kNavy, kAzure],
                            ),
                            border: Border.all(
                              color: kAzure.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.sync_alt_rounded,
                              color: kGold,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Text(
                        'Miane',
                        style: GoogleFonts.inter(
                          color: kLight,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _subFade,
                    child: SlideTransition(
                      position: _subSlide,
                      child: Text(
                        'Đồng hành cùng chuyến đi của bạn',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.beVietnamPro(
                          color: kAzure.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Login Options List
                  _buildSocialButton(
                    context: context,
                    icon: Icons.apple_rounded,
                    label: 'Tiếp tục với Apple',
                    onTap: _isLoading ? () {} : () => ref.read(appAuthProvider.notifier).loginFake(),
                    color: Colors.white,
                    textColor: Colors.black,
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButton(
                    context: context,
                    iconWidget: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomPaint(
                        painter: GoogleGLogoPainter(),
                      ),
                    ),
                    label: 'Tiếp tục với Google',
                    onTap: _isLoading ? () {} : _handleGoogleSignIn,
                    color: Colors.transparent,
                    textColor: kLight,
                    borderColor: kAzure.withOpacity(0.4),
                  ),


                  const SizedBox(height: 16),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: kLight.withOpacity(0.1),
                          thickness: 0.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'HOẶC',
                          style: GoogleFonts.beVietnamPro(
                            color: kLight.withOpacity(0.3),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: kLight.withOpacity(0.1),
                          thickness: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Email Login Button
                  _buildSocialButton(
                    context: context,
                    icon: Icons.email_rounded,
                    label: 'Sử dụng Email',
                    onTap: _isLoading
                        ? () {}
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                    color: Colors.transparent,
                    textColor: kLight,
                    borderColor: kAzure.withOpacity(0.4),
                  ),
                  const Spacer(flex: 1),
                  // Register redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: GoogleFonts.beVietnamPro(
                          color: kLight.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                );
                              },
                        child: Text(
                          'Đăng ký ngay',
                          style: GoogleFonts.beVietnamPro(
                            color: kAzure,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          color: kNavy.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kAzure.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: kAzure,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Đang kết nối...',
                              style: GoogleFonts.beVietnamPro(
                                color: kLight,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12), // rounded: md (12px)
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.0)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget
            else if (icon != null)
              Icon(
                icon,
                color: textColor,
                size: 24,
              ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleGLogoPainter extends CustomPainter {
  const GoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double strokeWidth = w * 0.22;
    final double r = w / 2 - strokeWidth / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: center, radius: r);

    // Google red (top)
    canvas.drawArc(rect, -2.4, 1.9, false, paint..color = const Color(0xFFEA4335));

    // Google yellow (left)
    canvas.drawArc(rect, 2.5, 1.0, false, paint..color = const Color(0xFFFBBC05));

    // Google green (bottom)
    canvas.drawArc(rect, 0.9, 1.6, false, paint..color = const Color(0xFF34A853));

    // Google blue (right/arc)
    canvas.drawArc(rect, -0.18, 1.1, false, paint..color = const Color(0xFF4285F4));

    // Google blue (horizontal bar)
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    final Rect barRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      w / 2,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
