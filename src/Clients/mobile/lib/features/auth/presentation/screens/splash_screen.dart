import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animation segments
  late final Animation<double> _flightAnimation;
  late final Animation<double> _morphAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<double> _textTranslateAnimation;
  late final Animation<double> _glowAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Total animation timeline is 3000ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Stage 1: Jet Launch Core (0ms - 1200ms -> [0.0, 0.4])
    // Accelerates upward from bottom to center with ease-in exponential curve
    _flightAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInExpo),
    );

    // Stage 2: Logo Morphing (1200ms - 2000ms -> [0.4, 0.67])
    // Shape morphing runs for exactly 450ms (1200ms - 1650ms -> [0.4, 0.55])
    _morphAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.55, curve: Curves.easeInOutCubic),
    );

    // Stage 3: Editorial Fade-In (2000ms - 2800ms -> [0.67, 0.93])
    // Text fades in and translates upward by 16dp via spring-out curve
    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.67, 0.93, curve: Curves.easeIn),
    );

    _textTranslateAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.67, 0.93, curve: Curves.easeOutBack),
    );

    // Ambient background glow pulse driven by the morphing progression
    _glowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOutSine),
    );

    // Stage 4: Navigation Route
    // Automatically trigger transition after 3000ms
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToOnboarding();
      }
    });

    _controller.forward();
  }

  void _navigateToOnboarding() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color surfaceDark = Color(0xFF05101E); // Deep Abyss

    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: surfaceDark,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Compute positioning and scaling for Stage 1 flight
          final double flightVal = _flightAnimation.value;
          final double yOffset = (1.0 - flightVal) * (screenHeight / 2 + 100);
          final double logoScale = 0.1 + (0.9 * flightVal);

          // Compute translation for Stage 3 text
          final double textTranslation =
              16.0 * (1.0 - _textTranslateAnimation.value);

          return Stack(
            children: [
              // Luminous Center Vector Logo Container
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, -yOffset),
                  child: Transform.scale(
                    scale: logoScale,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: MianeLogoPainter(
                          morphProgress: _morphAnimation.value,
                          glowProgress: _glowAnimation.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Editorial Greeting & Slogan
              Positioned(
                left: 0,
                right: 0,
                bottom: screenHeight * 0.15 + textTranslation,
                child: Opacity(
                  opacity: _textFadeAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xin chào! Hãy bắt đầu hành trình của bạn cùng Miane',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            color: const Color(0xFFF8F9FA), // Surface Light
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Đồng bộ lịch trình, đơn giản chi tiêu.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            color: const Color(0xFF4A90E2), // Luminous Azure
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
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

class MianeLogoPainter extends CustomPainter {
  final double morphProgress;
  final double glowProgress;

  MianeLogoPainter({
    required this.morphProgress,
    required this.glowProgress,
  });

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw Cinematic Background Radial Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x334A90E2), // Luminous Azure (20% opacity)
          const Color(0x0C0D2C54), // Heritage Navy (5% opacity)
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: 120.0 + 30.0 * glowProgress,
        ),
      );

    canvas.drawCircle(center, 180.0, glowPaint);

    // 2. Draw Vector Components of the Logo
    // Let's draw the components: Outer wing/ring, Inner wing/ring, beak/arrowhead 1, tail/arrowhead 2, crest/hub.

    // --- Outer Ring / Wing 1 ---
    final Color outerColor = Color.lerp(
      const Color(0xFFF4BD64), // Accent Gold
      const Color(0xFF4A90E2), // Luminous Azure
      morphProgress,
    )!;

    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _lerp(5.0, 7.5, morphProgress)
      ..strokeCap = StrokeCap.round;

    final double outerRadius = _lerp(24.0, 42.0, morphProgress);
    final double outerStartAngle = _lerp(1.85 * math.pi, -0.5 * math.pi, morphProgress);
    final double outerSweepAngle = _lerp(1.2 * math.pi, 1.65 * math.pi, morphProgress);
    final Offset outerCenter = Offset.lerp(
      const Offset(8, -12),
      Offset.zero,
      morphProgress,
    )!;

    canvas.drawArc(
      Rect.fromCircle(center: center + outerCenter, radius: outerRadius),
      outerStartAngle,
      outerSweepAngle,
      false,
      outerPaint,
    );

    // --- Inner Ring / Wing 2 ---
    final innerPaint = Paint()
      ..color = const Color(0xFFF4BD64) // Accent Gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = _lerp(4.0, 5.5, morphProgress)
      ..strokeCap = StrokeCap.round;

    final double innerRadius = _lerp(16.0, 26.0, morphProgress);
    final double innerStartAngle = _lerp(0.2 * math.pi, 0.5 * math.pi, morphProgress);
    final double innerSweepAngle = _lerp(1.1 * math.pi, 1.65 * math.pi, morphProgress);
    final Offset innerCenter = Offset.lerp(
      const Offset(-8, 12),
      Offset.zero,
      morphProgress,
    )!;

    canvas.drawArc(
      Rect.fromCircle(center: center + innerCenter, radius: innerRadius),
      innerStartAngle,
      innerSweepAngle,
      false,
      innerPaint,
    );

    // --- Outer Arrowhead / Beak ---
    final fillPaintOuter = Paint()
      ..color = outerColor
      ..style = PaintingStyle.fill;

    final pathOuterArrow = Path();
    final Offset oaTip = Offset.lerp(
      const Offset(-35, -20),
      const Offset(-40, -13),
      morphProgress,
    )!;
    final Offset oaBase1 = Offset.lerp(
      const Offset(-12, -28),
      const Offset(-45, -4),
      morphProgress,
    )!;
    final Offset oaBase2 = Offset.lerp(
      const Offset(-14, -14),
      const Offset(-31, -19),
      morphProgress,
    )!;

    pathOuterArrow.moveTo(center.dx + oaTip.dx, center.dy + oaTip.dy);
    pathOuterArrow.lineTo(center.dx + oaBase1.dx, center.dy + oaBase1.dy);
    pathOuterArrow.lineTo(center.dx + oaBase2.dx, center.dy + oaBase2.dy);
    pathOuterArrow.close();
    canvas.drawPath(pathOuterArrow, fillPaintOuter);

    // --- Inner Arrowhead / Tail ---
    final fillPaintInner = Paint()
      ..color = const Color(0xFFF4BD64) // Accent Gold
      ..style = PaintingStyle.fill;

    final pathInnerArrow = Path();
    final Offset iaTip = Offset.lerp(
      const Offset(32, 20),
      const Offset(24.7, 8.0),
      morphProgress,
    )!;
    final Offset iaBase1 = Offset.lerp(
      const Offset(10, 8),
      const Offset(19.0, 16.0),
      morphProgress,
    )!;
    final Offset iaBase2 = Offset.lerp(
      const Offset(16, 26),
      const Offset(31.0, 2.0),
      morphProgress,
    )!;

    pathInnerArrow.moveTo(center.dx + iaTip.dx, center.dy + iaTip.dy);
    pathInnerArrow.lineTo(center.dx + iaBase1.dx, center.dy + iaBase1.dy);
    pathInnerArrow.lineTo(center.dx + iaBase2.dx, center.dy + iaBase2.dy);
    pathInnerArrow.close();
    canvas.drawPath(pathInnerArrow, fillPaintInner);

    // --- Central Hub / Crest ---
    final fillPaintHub = Paint()
      ..color = Color.lerp(
        const Color(0xFFF4BD64), // Accent Gold
        const Color(0xFF4A90E2), // Luminous Azure
        morphProgress,
      )!
      ..style = PaintingStyle.fill;

    final pathHub = Path();
    final Offset h1 = Offset.lerp(
      const Offset(-18, -25),
      const Offset(-3, -3),
      morphProgress,
    )!;
    final Offset h2 = Offset.lerp(
      const Offset(-8, -26),
      const Offset(3, -3),
      morphProgress,
    )!;
    final Offset h3 = Offset.lerp(
      const Offset(-12, -18),
      const Offset(3, 3),
      morphProgress,
    )!;
    final Offset h4 = Offset.lerp(
      const Offset(-22, -19),
      const Offset(-3, 3),
      morphProgress,
    )!;

    pathHub.moveTo(center.dx + h1.dx, center.dy + h1.dy);
    pathHub.lineTo(center.dx + h2.dx, center.dy + h2.dy);
    pathHub.lineTo(center.dx + h3.dx, center.dy + h3.dy);
    pathHub.lineTo(center.dx + h4.dx, center.dy + h4.dy);
    pathHub.close();
    canvas.drawPath(pathHub, fillPaintHub);
  }

  @override
  bool shouldRepaint(covariant MianeLogoPainter oldDelegate) {
    return oldDelegate.morphProgress != morphProgress ||
        oldDelegate.glowProgress != glowProgress;
  }
}
