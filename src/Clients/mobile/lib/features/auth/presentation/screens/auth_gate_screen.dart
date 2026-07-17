import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../controllers/app_auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _loopController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  double _stagger(double start, double end) {
    final value =
        ((_introController.value - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(value);
  }

  Future<void> _signInWithGoogle(WidgetRef ref) async {
    try {
      // clientId / serverClientId are read from ios/Runner/Info.plist
      // (GIDClientID / GIDServerClientID). See GOOGLE_SIGNIN_SETUP.md.
      final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled the Google sheet — do nothing.
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken != null) {
        await ref.read(appAuthProvider.notifier).loginWithGoogle(idToken);
        return;
      }
      // No idToken (misconfigured client id). Fall through to dev fallback.
      throw StateError('Google sign-in returned no idToken');
    } catch (e) {
      const allowMockFallback = bool.fromEnvironment(
        'GOOGLE_AUTH_ALLOW_MOCK_FALLBACK',
        defaultValue: false,
      );
      if (kDebugMode && allowMockFallback) {
        debugPrint('Google sign-in failed, using explicit dev fallback: $e');
        await ref
            .read(appAuthProvider.notifier)
            .loginWithGoogle('mock_google_token');
        return;
      }
      debugPrint('Google sign-in failed: $e');
      if (mounted) {
        await showIosMessage(
          context,
          message: 'Không thể đăng nhập Google. Vui lòng kiểm tra cấu hình '
              'OAuth hoặc thử lại.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      child: AnimatedBuilder(
        animation: Listenable.merge([_introController, _loopController]),
        builder: (context, _) {
          final loop = _loopController.value;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AuthBackdropPainter(progress: loop),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      _AnimatedEntry(
                        progress: _stagger(0.00, 0.42),
                        dy: 24,
                        scaleBegin: 0.88,
                        child: _MianeLogo(progress: loop),
                      ),
                      const SizedBox(height: 26),
                      _AnimatedEntry(
                        progress: _stagger(0.10, 0.54),
                        dy: 18,
                        child: Text('Miane', style: AppTheme.displayLg()),
                      ),
                      const SizedBox(height: 8),
                      _AnimatedEntry(
                        progress: _stagger(0.18, 0.62),
                        dy: 18,
                        child: Text(
                          'Đồng hành cùng chuyến đi của bạn',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMd(
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      _AnimatedEntry(
                        progress: _stagger(0.38, 0.72),
                        dy: 28,
                        child: _AuthButton(
                          label: 'Tiếp tục với Apple',
                          backgroundColor: CupertinoColors.white,
                          foregroundColor: CupertinoColors.black,
                          icon: Icons.apple,
                          borderColor:
                              CupertinoColors.white.withValues(alpha: 0.24),
                          shadowColor:
                              CupertinoColors.white.withValues(alpha: 0.18),
                          onPressed: () => showIosMessage(
                            context,
                            message: 'Đăng nhập Apple chưa được cấu hình.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedEntry(
                        progress: _stagger(0.48, 0.82),
                        dy: 28,
                        child: _AuthButton(
                          label: 'Tiếp tục với Google',
                          backgroundColor: AppTheme.surfaceDark,
                          foregroundColor: AppTheme.iosLight,
                          iconWidget: const _GoogleMark(),
                          onPressed: () => _signInWithGoogle(ref),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedEntry(
                        progress: _stagger(0.58, 0.92),
                        dy: 28,
                        child: _AuthButton(
                          label: 'Sử dụng Email',
                          backgroundColor: AppTheme.surfaceDark,
                          foregroundColor: AppTheme.iosBlue,
                          icon: CupertinoIcons.mail,
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AnimatedEntry(
                        progress: _stagger(0.70, 1.00),
                        dy: 18,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Chưa có tài khoản? Đăng ký ngay',
                            style: AppTheme.bodySm(color: AppTheme.iosBlue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final double progress;
  final double dy;
  final double scaleBegin;
  final Widget child;

  const _AnimatedEntry({
    required this.progress,
    required this.child,
    this.dy = 16,
    this.scaleBegin = 0.98,
  });

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);

    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, (1 - value) * dy),
        child: Transform.scale(
          scale: scaleBegin + ((1 - scaleBegin) * value),
          child: child,
        ),
      ),
    );
  }
}

class _MianeLogo extends StatelessWidget {
  final double progress;

  const _MianeLogo({required this.progress});

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(progress * math.pi * 2);

    return Transform.translate(
      offset: Offset(0, wave * 5),
      child: SizedBox(
        width: 108,
        height: 108,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LogoOrbitPainter(progress: progress),
              ),
            ),
            Transform.scale(
              scale: 1 + (wave * 0.025),
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF36B7FF),
                      AppTheme.iosBlue,
                      AppTheme.iosIndigo,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.iosBlue.withValues(alpha: 0.36),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
              ),
            ),
            Transform.rotate(
              angle: progress * math.pi * 2,
              child: const Icon(
                CupertinoIcons.arrow_2_circlepath,
                color: CupertinoColors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatefulWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? borderColor;
  final Color? shadowColor;
  final VoidCallback? onPressed;

  const _AuthButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.icon,
    this.iconWidget,
    this.borderColor,
    this.shadowColor,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || widget.onPressed == null) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.borderColor ?? CupertinoColors.white.withValues(alpha: 0.08);

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          pressedOpacity: 0.9,
          onPressed: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderColor, width: 0.7),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor ??
                      CupertinoColors.black.withValues(alpha: 0.26),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.iconWidget != null) ...[
                  widget.iconWidget!,
                  const SizedBox(width: 9),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.foregroundColor, size: 22),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.foregroundColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Rect.fromLTWH(
      stroke,
      stroke,
      size.width - stroke * 2,
      size.height - stroke * 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    void arc(Color color, double start, double sweep) {
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    arc(const Color(0xFFEA4335), math.pi * 1.02, math.pi * 0.58);
    arc(const Color(0xFFFBBC05), math.pi * 0.58, math.pi * 0.47);
    arc(const Color(0xFF34A853), math.pi * 0.08, math.pi * 0.56);
    arc(const Color(0xFF4285F4), -math.pi * 0.18, math.pi * 0.34);

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.50),
      Offset(size.width * 0.92, size.height * 0.50),
      bluePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.90, size.height * 0.50),
      Offset(size.width * 0.82, size.height * 0.68),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoOrbitPainter extends CustomPainter {
  final double progress;

  const _LogoOrbitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 2; i++) {
      final phase = (progress + i * 0.5) % 1;
      final radius = 36 + phase * 18;
      paint.color = AppTheme.iosBlue.withValues(alpha: (1 - phase) * 0.22);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AuthBackdropPainter extends CustomPainter {
  final double progress;

  const _AuthBackdropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final t = progress * math.pi * 2;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppTheme.canvasDark,
    );

    final topPath = Path()
      ..moveTo(0, height * (0.12 + math.sin(t) * 0.012))
      ..cubicTo(
        width * 0.25,
        height * (0.05 + math.cos(t * 0.8) * 0.018),
        width * 0.68,
        height * (0.20 + math.sin(t * 0.7) * 0.014),
        width,
        height * (0.10 + math.cos(t) * 0.012),
      )
      ..lineTo(width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(
      topPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x662BAEFF),
            Color(0x305E5CE6),
            Color(0x00000000),
          ],
        ).createShader(Rect.fromLTWH(0, 0, width, height * 0.38))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    final midPath = Path()
      ..moveTo(0, height * (0.38 + math.cos(t) * 0.018))
      ..cubicTo(
        width * 0.22,
        height * (0.31 + math.sin(t * 0.9) * 0.02),
        width * 0.58,
        height * (0.46 + math.cos(t * 0.7) * 0.016),
        width,
        height * (0.36 + math.sin(t) * 0.016),
      )
      ..lineTo(width, height * 0.58)
      ..cubicTo(
        width * 0.70,
        height * (0.50 + math.cos(t) * 0.016),
        width * 0.26,
        height * (0.62 + math.sin(t * 0.6) * 0.018),
        0,
        height * 0.52,
      )
      ..close();

    canvas.drawPath(
      midPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x24FF2D55),
            Color(0x1FFF9F0A),
            Color(0x220A84FF),
          ],
        ).createShader(Rect.fromLTWH(0, height * 0.28, width, height * 0.36))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    final bottomPath = Path()
      ..moveTo(0, height)
      ..lineTo(0, height * (0.80 + math.sin(t * 0.6) * 0.012))
      ..cubicTo(
        width * 0.28,
        height * (0.72 + math.cos(t * 0.7) * 0.016),
        width * 0.64,
        height * (0.88 + math.sin(t) * 0.016),
        width,
        height * (0.78 + math.cos(t * 0.8) * 0.012),
      )
      ..lineTo(width, height)
      ..close();

    canvas.drawPath(
      bottomPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0x330A84FF),
            Color(0x1A30D158),
            Color(0x00000000),
          ],
        ).createShader(Rect.fromLTWH(0, height * 0.66, width, height * 0.34))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    final linePaint = Paint()
      ..color = CupertinoColors.white.withValues(alpha: 0.035)
      ..strokeWidth = 0.7;
    for (var i = 0; i < 6; i++) {
      final y = height * (0.22 + i * 0.11) + math.sin(t + i) * 2.5;
      canvas.drawLine(Offset(18, y), Offset(width - 18, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuthBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
