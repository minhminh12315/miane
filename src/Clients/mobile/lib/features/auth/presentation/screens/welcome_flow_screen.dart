import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../controllers/app_auth_provider.dart';

import '../../../../core/theme/app_theme.dart';

part 'welcome_flow_screen.g.dart';

// ── DESIGN SYSTEM TOKENS (DESIGN.md) ─────────────────────────────────────────
const Color _kDark = AppTheme.canvasDark;       // iOS Canvas Black
const Color _kNavy = AppTheme.surfaceDark;       // iOS Grouped Surface Dark
const Color _kAzure = AppTheme.iosBlue;      // iOS System Blue
const Color _kGold = AppTheme.iosGold;       // iOS Amber/Gold
const Color _kLight = AppTheme.iosLight;      // iOS System Light

// ── STATE MANAGEMENT ────────────────────────────────────────────────────────
// Manage onboarding active step index (0 to 2) using Riverpod Notifier Generator
@riverpod
class WelcomeFlowPageIndex extends _$WelcomeFlowPageIndex {
  @override
  int build() => 0;

  void setPage(int index) {
    state = index;
  }
}

// ── MAIN SCREEN ──────────────────────────────────────────────────────────────
class WelcomeFlowScreen extends ConsumerStatefulWidget {
  const WelcomeFlowScreen({super.key});

  @override
  ConsumerState<WelcomeFlowScreen> createState() => _WelcomeFlowScreenState();
}

class _WelcomeFlowScreenState extends ConsumerState<WelcomeFlowScreen>
    with TickerProviderStateMixin {
  
  // Timeline Animation Controller (for linear narrative progression)
  late final AnimationController _timelineController;
  
  // Continuous Repeating Controller (for 3D tilt, shimmers, and glow pulsing)
  late final AnimationController _loopController;

  // Page controller for onboarding steps
  late final PageController _pageController;

  // Staggered timeline animations
  late final Animation<double> _glowFade;
  late final Animation<double> _logoFadeIn;
  late final Animation<double> _logoScaleIn;
  late final Animation<double> _cardsFadeIn;
  late final Animation<double> _cardsScaleIn;
  late final Animation<double> _cardsCollapse;
  late final Animation<double> _logoGlide;
  late final Animation<double> _headerFadeIn;
  late final Animation<double> _sloganFadeIn;
  late final Animation<double> _sheetSlideIn;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 1. Narrative timeline controller (3800ms total duration)
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    // 2. Loop controller for active environmental micro-oscillations (6000ms duration)
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // ── ANIMATION INTERVAL DEFINITIONS ──
    
    // Phase 1 (0ms - 1000ms) -> Interval [0.0, 0.26]
    _glowFade = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );
    _logoFadeIn = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.05, 0.26, curve: Curves.easeIn),
    );
    // Custom spring-like curve for logo entrance
    _logoScaleIn = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.05, 0.26, curve: Curves.easeOutBack),
    );

    // Phase 2 (1000ms - 2500ms) -> Interval [0.26, 0.65]
    _cardsFadeIn = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.26, 0.38, curve: Curves.easeIn),
    );
    _cardsScaleIn = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.26, 0.42, curve: Curves.easeOutBack),
    );

    // Phase 3 (2500ms - 3000ms) -> Interval [0.65, 0.79]
    _cardsCollapse = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.65, 0.74, curve: Curves.easeInCubic),
    );
    _logoGlide = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.65, 0.82, curve: Curves.easeInOutCubic),
    );
    _headerFadeIn = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.70, 0.82, curve: Curves.easeInOutCubic),
    );
    _sloganFadeIn = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.74, 0.87, curve: Curves.easeOut),
    );

    // Phase 4 (3000ms - 3800ms) -> Interval [0.79, 1.0]
    _sheetSlideIn = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.79, 1.0, curve: Curves.easeOutCubic),
    );

    // Kick off transition flow
    _timelineController.forward();
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _loopController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Define coordinates for logo gliding animation
    final Offset centerLogoPos = Offset(size.width / 2, size.height / 2 - 40);
    // Left-aligned in the Floating Header layout
    final Offset headerLogoPos = Offset(50.0, topPadding + 48.0);

    return Scaffold(
      backgroundColor: _kDark,
      body: Stack(
        children: [
          // ── BACKGROUND GLOW (Phase 1 & Continuous Pulsing) ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_timelineController, _loopController]),
              builder: (context, child) {
                // Pulse value between 0.0 and 1.0
                final double pulse = math.sin(_loopController.value * 2 * math.pi) * 0.5 + 0.5;
                // Intro fade value
                final double introOpacity = _glowFade.value;
                return CustomPaint(
                  painter: _GlowPainter(
                    pulseValue: pulse,
                    opacityMultiplier: introOpacity,
                  ),
                );
              },
            ),
          ),

          // ── LAYERED 3D GLASSMORPHISM CARDS (Phase 2) ──
          _buildGlassCards(size),

          // ── FLOATING HEADER (Phase 3 & 4) ──
          Positioned(
            top: topPadding + 16,
            left: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _headerFadeIn,
              builder: (context, child) {
                final double opacity = _headerFadeIn.value.clamp(0.0, 1.0);
                final double yTranslate = (1.0 - opacity) * -20.0;
                return Transform.translate(
                  offset: Offset(0, yTranslate),
                  child: Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kNavy.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Space reserved for the logo to glide into
                        const SizedBox(width: 36, height: 36),
                        
                        // Theme Morphing / Active state indicator capsule
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kDark.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _kAzure.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wb_sunny_rounded, color: _kGold, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'DARK MODE',
                                style: GoogleFonts.beVietnamPro(
                                  color: _kLight,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Rounded Premium User Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kAzure, _kNavy],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _kGold.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kAzure.withOpacity(0.2),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: _kLight,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── SLOGAN TEXT (Phase 3) ──
          Positioned(
            top: topPadding + 16 + 64 + 18,
            left: 24,
            right: 24,
            child: AnimatedBuilder(
              animation: _sloganFadeIn,
              builder: (context, child) {
                final double opacity = _sloganFadeIn.value.clamp(0.0, 1.0);
                final double yTranslate = (1.0 - opacity) * 12.0;
                return Transform.translate(
                  offset: Offset(0, yTranslate),
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      'Đồng bộ lịch trình, đơn giản chi tiêu.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── LOGO (Phase 1, 2, 3 & 4) ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_timelineController, _loopController]),
              builder: (context, child) {
                // Smooth morph between center and top-left header coordinates
                final double glideProgress = _logoGlide.value;
                final Offset currentLogoPos = Offset.lerp(
                  centerLogoPos,
                  headerLogoPos,
                  glideProgress,
                )!;

                final double currentLogoSize = lerpDouble(130.0, 36.0, glideProgress)!;

                // Scale and Opacity adjustments for entry/fade-in
                final double introOpacity = _logoFadeIn.value.clamp(0.0, 1.0);
                final double introScale = 0.8 + 0.2 * _logoScaleIn.value;

                // Compute slight 3D float offset to match parallax feeling
                final double tiltY = math.cos(_loopController.value * 2 * math.pi) * 4.0;
                final double floatOffset = (1.0 - glideProgress) * tiltY;

                return Stack(
                  children: [
                    Positioned(
                      left: currentLogoPos.dx - currentLogoSize / 2,
                      top: currentLogoPos.dy - currentLogoSize / 2 + floatOffset,
                      child: Opacity(
                        opacity: introOpacity,
                        child: Transform.scale(
                          scale: introScale,
                          child: Hero(
                            tag: 'app-logo',
                            child: Container(
                              width: currentLogoSize,
                              height: currentLogoSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  if (glideProgress < 0.8)
                                    BoxShadow(
                                      color: _kAzure.withOpacity(0.15),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(currentLogoSize * 0.2),
                                child: Image.asset(
                                  'assets/images/miane-logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── ONBOARDING DETACHED SHEET (Phase 4) ──
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 16,
            child: AnimatedBuilder(
              animation: _sheetSlideIn,
              builder: (context, child) {
                final double slideProgress = _sheetSlideIn.value.clamp(0.0, 1.0);
                final double yTranslation = (1.0 - slideProgress) * size.height * 0.7;

                return Transform.translate(
                  offset: Offset(0, yTranslation),
                  child: Opacity(
                    opacity: slideProgress,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                height: size.height * 0.58,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _kNavy.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Drag handle visualizer
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Active Step Presentation Pages
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                ref.read(welcomeFlowPageIndexProvider.notifier).setPage(index);
                              },
                              children: const [
                                _StepTimelinePage(),
                                _StepExpensePage(),
                                _StepPaymentPage(),
                              ],
                            ),
                          ),
                          
                          // Bottom Navigation row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Dots indicator
                                _DotsIndicator(pageController: _pageController),
                                
                                // CTA action trigger
                                _CtaButton(pageController: _pageController),
                              ],
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

  // Helper builder for 3D Layered Glassmorphism Cards (Phase 2)
  Widget _buildGlassCards(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_timelineController, _loopController]),
        builder: (context, child) {
          final double introProgress = _cardsFadeIn.value;
          final double introScale = 0.8 + 0.2 * _cardsScaleIn.value;
          final double collapseProgress = _cardsCollapse.value;

          // Compute absolute card status visibility
          final double opacity = (introProgress * (1.0 - collapseProgress)).clamp(0.0, 1.0);
          if (opacity <= 0.0) return const SizedBox.shrink();

          // Continuous micro-oscillations driven by the loop controller
          final double time = _loopController.value * 2 * math.pi;

          return Stack(
            children: List.generate(3, (index) {
              double angleX = 0.0;
              double angleY = 0.0;
              double dx = 0.0;
              double dy = 0.0;
              double cardW = 100.0;
              double cardH = 100.0;
              Color cardBorderColor = _kAzure.withOpacity(0.4);

              // Stagger card phases for out-of-sync 3D parallax offsets
              if (index == 0) {
                // Card 1: Background Glass Card (Behind center logo)
                angleX = math.sin(time) * 0.08;
                angleY = math.cos(time) * 0.08;
                dx = -70.0 + (angleY * 20.0);
                dy = -80.0 + (angleX * 20.0);
                cardW = 160.0;
                cardH = 100.0;
                cardBorderColor = _kAzure.withOpacity(0.3);
              } else if (index == 1) {
                // Card 2: Foreground Card Left (In front of logo)
                angleX = math.cos(time + 1.2) * 0.1;
                angleY = math.sin(time + 1.2) * 0.1;
                dx = -50.0 + (angleY * 35.0);
                dy = 70.0 + (angleX * 35.0);
                cardW = 110.0;
                cardH = 70.0;
                cardBorderColor = _kGold.withOpacity(0.3);
              } else {
                // Card 3: Foreground Card Right (In front of logo)
                angleX = math.sin(time + 2.4) * 0.12;
                angleY = math.cos(time + 2.4) * 0.06;
                dx = 70.0 + (angleY * 30.0);
                dy = -20.0 + (angleX * 30.0);
                cardW = 90.0;
                cardH = 90.0;
                cardBorderColor = _kLight.withOpacity(0.3);
              }

              // Shimmer linear sweep progress matching loop value
              final double shimmerVal = (_loopController.value * 2.0) % 1.0;

              return Positioned(
                left: size.width / 2 - cardW / 2 + dx,
                top: size.height / 2 - cardH / 2 - 40 + dy,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: introScale * (1.0 - collapseProgress * 0.2),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // 3D Perspective entry distortion
                        ..rotateX(angleX)
                        ..rotateY(angleY),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: CustomPaint(
                            painter: GlassCardPainter(
                              shimmerProgress: shimmerVal,
                              borderColor: cardBorderColor,
                              fillColor: _kNavy.withOpacity(0.25),
                            ),
                            child: SizedBox(
                              width: cardW,
                              height: cardH,
                              child: index == 1
                                  ? const Center(
                                      child: Icon(
                                        Icons.insights_rounded,
                                        color: _kGold,
                                        size: 24,
                                      ),
                                    )
                                  : index == 2
                                      ? const Center(
                                          child: Icon(
                                            Icons.auto_awesome_rounded,
                                            color: _kAzure,
                                            size: 22,
                                          ),
                                        )
                                      : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ── CUSTOM SHIMMER PAINTER ──────────────────────────────────────────────────
class GlassCardPainter extends CustomPainter {
  final double shimmerProgress;
  final Color borderColor;
  final Color fillColor;

  GlassCardPainter({
    required this.shimmerProgress,
    required this.borderColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // 1. Draw solid color background overlay
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // 2. Draw luxury glass shimmer light sweep
    final double shimmerWidth = size.width * 1.5;
    final double currentPos = -shimmerWidth / 2 + (size.width + shimmerWidth) * shimmerProgress;

    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.03),
          Colors.white.withOpacity(0.24), // central peak brightness
          Colors.white.withOpacity(0.03),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(
        Rect.fromLTWH(currentPos, 0, shimmerWidth, size.height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, shimmerPaint);

    // 3. Draw premium 1px border with a soft gradient
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          borderColor,
          borderColor.withOpacity(0.2),
          borderColor,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant GlassCardPainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.fillColor != fillColor;
  }
}

// ── AMBIENT RADIAL GLOW PAINTER ─────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  final double pulseValue;
  final double opacityMultiplier;

  _GlowPainter({required this.pulseValue, required this.opacityMultiplier});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Draw raw dark background
    canvas.drawRect(rect, Paint()..color = _kDark);

    // Draw azure radial pulsing aura
    final double maxOpacity = 0.15 * opacityMultiplier;
    final double opacity = 0.07 * opacityMultiplier + (0.08 * opacityMultiplier * pulseValue);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 0.9,
        colors: [
          _kAzure.withOpacity(opacity.clamp(0.0, maxOpacity)),
          _kNavy.withOpacity((opacity * 0.35).clamp(0.0, maxOpacity)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.opacityMultiplier != opacityMultiplier;
  }
}

// ── ONBOARDING STEP WIDGET: STEP 1 (TIMELINE PLANNING) ───────────────────────
class _StepTimelinePage extends StatelessWidget {
  const _StepTimelinePage();

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      visual: const _AnimatedTimelineMockup(),
      title: 'Đồng bộ lịch trình',
      body: 'Công cụ lập kế hoạch hành trình thông minh. Chia sẻ và chỉnh sửa lộ trình cùng bạn bè theo thời gian thực tế.',
    );
  }
}

class _AnimatedTimelineMockup extends StatefulWidget {
  const _AnimatedTimelineMockup();

  @override
  State<_AnimatedTimelineMockup> createState() => _AnimatedTimelineMockupState();
}

class _AnimatedTimelineMockupState extends State<_AnimatedTimelineMockup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = [
      ('08:00', 'Bay đi Đà Lạt', Icons.flight_takeoff_rounded, true),
      ('12:00', 'Ăn trưa lẩu gà lá é', Icons.restaurant_rounded, true),
      ('14:30', 'Nhận phòng Colline', Icons.hotel_rounded, false),
      ('18:00', 'Ngắm hoàng hôn Hồ Xuân Hương', Icons.photo_camera_rounded, false),
    ];

    return Stack(
      children: [
        // Connecting line
        Positioned(
          left: 19,
          top: 16,
          bottom: 16,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kAzure,
                  _kGold.withOpacity(0.15),
                ],
              ),
            ),
          ),
        ),
        // Timeline elements
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(nodes.length, (index) {
            final node = nodes[index];
            final double start = index * 0.18;
            final double end = (start + 0.45).clamp(0.0, 1.0);
            
            final anim = CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: Curves.easeOutBack),
            );

            return AnimatedBuilder(
              animation: anim,
              builder: (context, child) {
                final double val = anim.value;
                return Transform.translate(
                  offset: Offset(0, (1.0 - val) * 16.0),
                  child: Opacity(
                    opacity: val.clamp(0.0, 1.0),
                    child: Row(
                      children: [
                        // Node circle indicator
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: node.$4 ? _kNavy : _kDark,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: node.$4 ? _kAzure : _kAzure.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (node.$4)
                                BoxShadow(
                                  color: _kAzure.withOpacity(0.2),
                                  blurRadius: 6,
                                )
                            ],
                          ),
                          child: Icon(
                            node.$3,
                            color: node.$4 ? _kGold : Colors.white38,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Content card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _kNavy.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.04),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        node.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.beVietnamPro(
                                          color: _kLight,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        node.$1,
                                        style: GoogleFonts.beVietnamPro(
                                          color: _kAzure,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (node.$4)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: _kGold,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

// ── ONBOARDING STEP WIDGET: STEP 2 (EXPENSE BALANCING) ───────────────────────
class _StepExpensePage extends StatelessWidget {
  const _StepExpensePage();

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      visual: const _AnimatedExpenseMockup(),
      title: 'Đơn giản chi tiêu',
      body: 'Giải pháp tính toán thu chi thông minh. Tự động quy đổi, tổng hợp và chia đều hóa đơn nhóm, tránh mọi sự sai lệch.',
    );
  }
}

class _AnimatedExpenseMockup extends StatefulWidget {
  const _AnimatedExpenseMockup();

  @override
  State<_AnimatedExpenseMockup> createState() => _AnimatedExpenseMockupState();
}

class _AnimatedExpenseMockupState extends State<_AnimatedExpenseMockup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segments = [
      (0.48, _kAzure, 'Di chuyển'),
      (0.32, _kGold, 'Khách sạn'),
      (0.20, const Color(0xFFE57373), 'Ăn uống'),
    ];

    return Column(
      children: [
        const SizedBox(height: 12),
        // Donut visualization block
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _DonutChartPainter(
                        progress: _controller.value,
                        segments: segments,
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TỔNG CHI',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '8.5M đ',
                      style: GoogleFonts.beVietnamPro(
                        color: _kLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Breakdown cards
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: segments.length,
            itemBuilder: (context, index) {
              final seg = segments[index];
              final double start = 0.35 + index * 0.15;
              final double end = (start + 0.45).clamp(0.0, 1.0);
              
              final anim = CurvedAnimation(
                parent: _controller,
                curve: Interval(start, end, curve: Curves.easeOutBack),
              );

              return AnimatedBuilder(
                animation: anim,
                builder: (context, child) {
                  final double val = anim.value;
                  return Transform.scale(
                    scale: val,
                    child: Opacity(
                      opacity: val.clamp(0.0, 1.0),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _kNavy.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: seg.$2,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              seg.$3,
                              style: GoogleFonts.beVietnamPro(
                                color: _kLight.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(seg.$1 * 8.5).toStringAsFixed(1)}M đ',
                              style: GoogleFonts.beVietnamPro(
                                color: _kLight,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${(seg.$1 * 100).toStringAsFixed(0)}%)',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Donut custom painter drawing segments with smooth transitions
class _DonutChartPainter extends CustomPainter {
  final double progress;
  final List<(double, Color, String)> segments;

  _DonutChartPainter({required this.progress, required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    var startAngle = -math.pi / 2;

    for (final seg in segments) {
      final sweepAngle = seg.$1 * 2 * math.pi * progress;
      paint.color = seg.$2;
      
      // Arc with space gap
      canvas.drawArc(rect, startAngle + 0.04, sweepAngle - 0.08, false, paint);
      startAngle += seg.$1 * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.segments != segments;
  }
}

// ── ONBOARDING STEP WIDGET: STEP 3 (1-TOUCH PAYMENTS) ────────────────────────
class _StepPaymentPage extends StatelessWidget {
  const _StepPaymentPage();

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      visual: const _AnimatedPaymentMockup(),
      title: 'Quyết toán 1 chạm',
      body: 'Tích hợp thanh toán QR và Ví điện tử. Quét mã - tự động chia hóa đơn lẻ và giải quyết số dư nợ tức thì.',
    );
  }
}

class _AnimatedPaymentMockup extends StatefulWidget {
  const _AnimatedPaymentMockup();

  @override
  State<_AnimatedPaymentMockup> createState() => _AnimatedPaymentMockupState();
}

class _AnimatedPaymentMockupState extends State<_AnimatedPaymentMockup>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _entryController.forward();
    _laserController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // VietQR visual glass container
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kNavy.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kAzure.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Simulated QR Box with animated scanning laser
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/logo.png', // QR dummy visual
                        color: _kNavy,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      color: Colors.transparent,
                      child: CustomPaint(
                        painter: _QrMarkerPainter(),
                      ),
                    ),
                    // Active scanning laser
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Positioned(
                          top: _laserController.value * (56 - 2),
                          left: 2,
                          right: 2,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: _kAzure,
                              boxShadow: [
                                BoxShadow(
                                  color: _kAzure.withOpacity(0.8),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Liên kết VietQR',
                            style: GoogleFonts.beVietnamPro(
                              color: _kLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _kGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FREE',
                              style: GoogleFonts.beVietnamPro(
                                color: _kGold,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Thanh toán chuyển khoản liên ngân hàng nhận diện tức thì.',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white38,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // MoMo payment visual container
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.3, 0.9, curve: Curves.easeOutBack),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kNavy.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA50064),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'mơ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liên kết ví MoMo',
                        style: GoogleFonts.beVietnamPro(
                          color: _kLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Thanh toán tiện lợi, chia sẻ số tiền dư chuyển thẳng vào ví.',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white38,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QrMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _kNavy
      ..style = PaintingStyle.fill;
    
    // Top-left QR corner marker
    canvas.drawRect(const Rect.fromLTWH(3, 3, 14, 14), p);
    canvas.drawRect(const Rect.fromLTWH(5, 5, 10, 10), Paint()..color = Colors.white);
    canvas.drawRect(const Rect.fromLTWH(7, 7, 6, 6), p);
    
    // Top-right
    canvas.drawRect(Rect.fromLTWH(size.width - 17, 3, 14, 14), p);
    canvas.drawRect(Rect.fromLTWH(size.width - 15, 5, 10, 10), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(size.width - 13, 7, 6, 6), p);
    
    // Bottom-left
    canvas.drawRect(Rect.fromLTWH(3, size.height - 17, 14, 14), p);
    canvas.drawRect(Rect.fromLTWH(5, size.height - 15, 10, 10), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(7, size.height - 13, 6, 6), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── NARRATIVE STEP CONTAINER SHELL ───────────────────────────────────────────
class _StepShell extends StatelessWidget {
  final Widget visual;
  final String title, body;
  
  const _StepShell({required this.visual, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: visual,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: _kLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── DOTS INDICATOR COMPONENT ────────────────────────────────────────────────
class _DotsIndicator extends ConsumerWidget {
  final PageController pageController;

  const _DotsIndicator({required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(welcomeFlowPageIndexProvider);

    return Row(
      children: List.generate(3, (index) {
        final bool isActive = activeIndex == index;
        return GestureDetector(
          onTap: () {
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 6),
            height: 6,
            width: isActive ? 24 : 6,
            decoration: BoxDecoration(
              color: isActive ? _kGold : _kGold.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

// ── CTA BUTTON COMPONENT ────────────────────────────────────────────────────
class _CtaButton extends ConsumerWidget {
  final PageController pageController;

  const _CtaButton({required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(welcomeFlowPageIndexProvider);
    final bool isLastPage = activeIndex == 2;

    return GestureDetector(
      onTap: () {
        if (!isLastPage) {
          pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        } else {
          ref.read(appAuthProvider.notifier).completeWelcome();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kGold, Color(0xFFD4A040)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kAzure.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLastPage ? 'Bắt đầu' : 'Tiếp tục',
              style: GoogleFonts.beVietnamPro(
                color: _kDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              color: _kDark,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
