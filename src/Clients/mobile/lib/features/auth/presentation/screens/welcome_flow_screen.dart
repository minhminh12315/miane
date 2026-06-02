import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
const _kDark = Color(0xFF05101E);
const _kNavy = Color(0xFF0D2C54);
const _kAzure = Color(0xFF4A90E2);
const _kGold = Color(0xFFF4BD64);
const _kLight = Color(0xFFF8F9FA);

enum _Phase { bird, morph, text, onboarding }

// ── Entry point ────────────────────────────────────────────────────────────
class WelcomeFlowScreen extends StatefulWidget {
  const WelcomeFlowScreen({super.key});
  @override
  State<WelcomeFlowScreen> createState() => _WelcomeFlowScreenState();
}

class _WelcomeFlowScreenState extends State<WelcomeFlowScreen>
    with TickerProviderStateMixin {
  // controllers
  late final AnimationController _bird;  // 1 500 ms  – bezier flight
  late final AnimationController _morph; //   450 ms  – cross-fade
  late final AnimationController _txt;   //   800 ms  – staggered text
  late final AnimationController _trans; //   700 ms  – layout shift

  // derived animations
  late final Animation<double> _birdOpa, _birdScl;
  late final Animation<double> _morphVal;
  late final Animation<double> _greetOpa, _sloganOpa;
  late final Animation<Offset> _greetSlide, _sloganSlide;
  late final Animation<double> _sheetSlide, _hdrProgress, _logoShrink;

  _Phase _phase = _Phase.bird;
  final PageController _page = PageController();
  int _dot = 0;

  @override
  void initState() {
    super.initState();
    _bird  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _morph = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _txt   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _trans = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _birdOpa = CurvedAnimation(parent: _bird,  curve: const Interval(0, .5, curve: Curves.easeIn));
    _birdScl = CurvedAnimation(parent: _bird,  curve: Curves.elasticOut);
    _morphVal= CurvedAnimation(parent: _morph, curve: Curves.easeInOutCubic);

    _greetOpa  = CurvedAnimation(parent: _txt, curve: const Interval(0, .65, curve: Curves.easeOut));
    _sloganOpa = CurvedAnimation(parent: _txt, curve: const Interval(.3, 1,  curve: Curves.easeOut));
    _greetSlide  = Tween(begin: const Offset(0, .35), end: Offset.zero)
        .animate(CurvedAnimation(parent: _txt, curve: const Interval(0, .65, curve: Curves.easeOutBack)));
    _sloganSlide = Tween(begin: const Offset(0, .45), end: Offset.zero)
        .animate(CurvedAnimation(parent: _txt, curve: const Interval(.3, 1,  curve: Curves.easeOutBack)));

    _sheetSlide  = CurvedAnimation(parent: _trans, curve: const Interval(.15, 1, curve: Curves.easeOutCubic));
    _hdrProgress = CurvedAnimation(parent: _trans, curve: Curves.easeInOutCubic);
    _logoShrink  = CurvedAnimation(parent: _trans, curve: Curves.easeInOutCubic);

    _run();
  }

  Future<void> _run() async {
    await _bird.forward();
    setState(() => _phase = _Phase.morph);
    await _morph.forward();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    setState(() => _phase = _Phase.text);
    await _txt.forward();
    await Future<void>.delayed(const Duration(milliseconds: 550));
    setState(() => _phase = _Phase.onboarding);
    await _trans.forward();
  }

  @override
  void dispose() {
    _bird.dispose(); _morph.dispose(); _txt.dispose(); _trans.dispose();
    _page.dispose();
    super.dispose();
  }

  // Quadratic Bezier: bottom-left → center
  Offset _bezier(double t, Size s) {
    final p0 = Offset(-60, s.height + 60);
    final p1 = Offset(s.width * .18, s.height * .12);
    final p2 = Offset(s.width * .5,  s.height * .5);
    final mt = 1 - t;
    return Offset(
      mt*mt*p0.dx + 2*mt*t*p1.dx + t*t*p2.dx,
      mt*mt*p0.dy + 2*mt*t*p1.dy + t*t*p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size  = MediaQuery.of(context).size;
    final top   = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kDark,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bird, _morph, _txt, _trans]),
        builder: (ctx, _) {
          // Logo position & size
          final bPos       = _bezier(_bird.value, size);
          final isOnboard  = _phase == _Phase.onboarding;
          final targetHdrY = top + 24.0;
          final logoSz     = isOnboard ? lerpDouble(160, 52, _logoShrink.value)! : 160.0;
          final logoX      = isOnboard ? size.width / 2 : bPos.dx;
          final logoY      = isOnboard
              ? lerpDouble(size.height / 2, targetHdrY + logoSz / 2, _hdrProgress.value)!
              : bPos.dy;

          return Stack(
            children: [
              // ── ambient glow ──
              Positioned.fill(child: CustomPaint(painter: _GlowPainter())),

              // ── logo ──
              Positioned(
                left: logoX - logoSz / 2,
                top:  logoY - logoSz / 2,
                child: _LogoWidget(
                  phase: _phase,
                  size:  logoSz,
                  birdOpa: _birdOpa.value,
                  birdScl: .1 + .9 * _birdScl.value,
                  morphVal: _morphVal.value,
                ),
              ),

              // ── greeting + slogan ──
              if (_phase == _Phase.text)
                Positioned(
                  left: 32, right: 32,
                  bottom: size.height * .18,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SlideTransition(
                        position: _greetSlide,
                        child: FadeTransition(
                          opacity: _greetOpa,
                          child: Text(
                            'Xin chao! Bat dau hanh trinh\ncua ban cung TripSync',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.beVietnamPro(
                              color: _kLight, fontSize: 19,
                              fontWeight: FontWeight.w700, height: 1.45,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SlideTransition(
                        position: _sloganSlide,
                        child: FadeTransition(
                          opacity: _sloganOpa,
                          child: Text(
                            'Dong bo lich trinh, don gian chi tieu.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.beVietnamPro(
                              color: _kAzure, fontSize: 13,
                              fontWeight: FontWeight.w500, letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── onboarding sheet ──
              if (_phase == _Phase.onboarding)
                Positioned(
                  left: 0, right: 0,
                  top: top + 52 + 32,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _sheetSlide.value) * size.height * .75),
                    child: _OnboardSheet(
                      page: _page,
                      dot: _dot,
                      onDot: (i) => setState(() => _dot = i),
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

// ── Logo widget (bird → full logo cross-fade) ──────────────────────────────
class _LogoWidget extends StatelessWidget {
  final _Phase phase;
  final double size, birdOpa, birdScl, morphVal;
  const _LogoWidget({required this.phase, required this.size,
    required this.birdOpa, required this.birdScl, required this.morphVal});

  @override
  Widget build(BuildContext context) {
    if (phase == _Phase.bird) {
      return Opacity(
        opacity: birdOpa,
        child: Transform.scale(
          scale: birdScl,
          child: Image.asset('assets/images/logo.png',
              width: size, height: size, fit: BoxFit.contain),
        ),
      );
    }
    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        Opacity(
          opacity: (1 - morphVal).clamp(0, 1),
          child: Image.asset('assets/images/logo.png',
              width: size, height: size, fit: BoxFit.contain),
        ),
        Opacity(
          opacity: morphVal.clamp(0, 1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * .2),
            child: Image.asset('assets/images/miane-logo.png',
                width: size, height: size, fit: BoxFit.contain),
          ),
        ),
      ]),
    );
  }
}

// ── Ambient radial glow ────────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.width, s.height),
      Paint()..shader = RadialGradient(
        center: const Alignment(0, -.15), radius: .9,
        colors: [_kNavy.withValues(alpha: .55), _kDark],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.width, s.height),
      Paint()..shader = RadialGradient(
        center: Alignment.center, radius: .45,
        colors: [_kAzure.withValues(alpha: .08), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)),
    );
  }
  @override bool shouldRepaint(_) => false;
}

// ── Onboarding glassmorphism sheet ─────────────────────────────────────────
class _OnboardSheet extends StatelessWidget {
  final PageController page;
  final int dot;
  final ValueChanged<int> onDot;
  const _OnboardSheet({required this.page, required this.dot, required this.onDot});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: _kNavy.withValues(alpha: .88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top:   BorderSide(color: _kGold.withValues(alpha: .28), width: 1),
              left:  BorderSide(color: _kGold.withValues(alpha: .14), width: 1),
              right: BorderSide(color: _kGold.withValues(alpha: .14), width: 1),
            ),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 38, height: 4,
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(2),
              )),
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: page,
                onPageChanged: onDot,
                children: const [_Step1(), _Step2(), _Step3()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: dot == i ? 22 : 7, height: 7,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: dot == i ? _kGold : _kGold.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ))),
                  _CtaButton(page: page, dot: dot),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final PageController page;
  final int dot;
  const _CtaButton({required this.page, required this.dot});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (dot < 2) {
          page.nextPage(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeInOutCubic,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kGold, Color(0xFFD4A040)]),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(
            color: _kGold.withValues(alpha: .28),
            blurRadius: 14, offset: const Offset(0, 4),
          )],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(dot == 2 ? 'Bat dau' : 'Tiep tuc',
            style: GoogleFonts.beVietnamPro(
              color: _kDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 7),
          const Icon(Icons.arrow_forward_rounded, color: _kDark, size: 16),
        ]),
      ),
    );
  }
}

// ── Step helpers ───────────────────────────────────────────────────────────
class _StepShell extends StatelessWidget {
  final Widget visual;
  final String title, body;
  const _StepShell({required this.visual, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Center(child: visual)),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.playfairDisplay(
          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.2)),
        const SizedBox(height: 8),
        Text(body, style: GoogleFonts.beVietnamPro(
          color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w400, height: 1.6)),
        const SizedBox(height: 28),
      ]),
    );
  }
}

class _Step1 extends StatelessWidget {
  const _Step1();
  @override
  Widget build(BuildContext context) => _StepShell(
    visual: SizedBox(height: 200, width: double.infinity,
      child: CustomPaint(painter: _TimelinePainter())),
    title: 'Dong bo lich trinh',
    body: 'AI lap ke hoach chi tiet tung diem den. Chia se va chinh sua cung nhom theo thoi gian thuc.',
  );
}

class _Step2 extends StatelessWidget {
  const _Step2();
  @override
  Widget build(BuildContext context) => _StepShell(
    visual: SizedBox.square(dimension: 200, child: CustomPaint(painter: _PiePainter())),
    title: 'Don gian chi tieu',
    body: 'Tu dong phan chia chi phi nhom hop ly, minh bach. Khong con tinh toan tay.',
  );
}

class _Step3 extends StatelessWidget {
  const _Step3();
  @override
  Widget build(BuildContext context) => _StepShell(
    visual: SizedBox(height: 200, width: double.infinity,
      child: CustomPaint(painter: _PaymentPainter())),
    title: 'Quyet toan 1 cham',
    body: 'VietQR & MoMo tich hop truc tiep. Quet ma - thanh toan - hoan tat trong 3 giay.',
  );
}

// ── Timeline painter (Step 1) ──────────────────────────────────────────────
class _TimelinePainter extends CustomPainter {
  static const _items = [
    ('06:30', 'San bay Noi Bai', true),
    ('11:45', 'Nha tho Da Lat', true),
    ('14:00', 'Thung lung Tinh yeu', false),
    ('18:30', 'Ho Xuan Huong', false),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final lineX = s.width * .18;
    final rowH  = s.height / _items.length;

    // Vertical line
    canvas.drawLine(
      Offset(lineX, rowH * .4),
      Offset(lineX, s.height - rowH * .4),
      Paint()..color = _kGold.withValues(alpha: .25)..strokeWidth = 1.5,
    );

    for (var i = 0; i < _items.length; i++) {
      final (time, label, done) = _items[i];
      final cy = rowH * i + rowH * .5;

      // Dot
      canvas.drawCircle(Offset(lineX, cy), done ? 6 : 5,
        Paint()..color = done ? _kGold : _kAzure.withValues(alpha: .5));
      if (!done) {
        canvas.drawCircle(Offset(lineX, cy), 5,
          Paint()..color = _kAzure..strokeWidth = 1.5..style = PaintingStyle.stroke);
      }

      // Time
      _drawText(canvas, time, Offset(lineX - 44, cy - 8),
        _kGold, 10, FontWeight.w600);
      // Label
      _drawText(canvas, label, Offset(lineX + 16, cy - 8),
        done ? Colors.white : Colors.white38, 12,
        done ? FontWeight.w600 : FontWeight.w400);
    }
  }

  void _drawText(Canvas c, String txt, Offset o, Color col, double sz, FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(text: txt,
        style: TextStyle(color: col, fontSize: sz, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o);
  }

  @override bool shouldRepaint(_) => false;
}

// ── Pie chart painter (Step 2) ─────────────────────────────────────────────
class _PiePainter extends CustomPainter {
  static const _segs = [
    (0.38, _kGold,                  'Luu tru'),
    (0.26, _kAzure,                 'An uong'),
    (0.20, Color(0xFF7B5CF0),       'Di chuyen'),
    (0.16, Color(0xFF34D399),       'Vui choi'),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = math.min(s.width, s.height) * .38;
    var start = -math.pi / 2;

    for (final (pct, col, lbl) in _segs) {
      final sweep = pct * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start, sweep, true,
        Paint()..color = col,
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start, sweep, true,
        Paint()..color = _kDark..style = PaintingStyle.stroke..strokeWidth = 2,
      );

      // Label line
      final mid = start + sweep / 2;
      final lx  = c.dx + (r + 22) * math.cos(mid);
      final ly  = c.dy + (r + 22) * math.sin(mid);
      canvas.drawLine(
        Offset(c.dx + r * .8 * math.cos(mid), c.dy + r * .8 * math.sin(mid)),
        Offset(lx, ly),
        Paint()..color = col.withValues(alpha: .6)..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(text: '${(pct * 100).toStringAsFixed(0)}%\n$lbl',
          style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.w600, height: 1.3)),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center,
      )..layout(maxWidth: 56);
      tp.paint(canvas, Offset(lx - tp.width / 2, ly));

      start += sweep;
    }

    // Center hole
    canvas.drawCircle(c, r * .42, Paint()..color = _kNavy);
    final tp = TextPainter(
      text: TextSpan(text: '4 muc\nchi phi',
        style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 10, height: 1.4)),
      textDirection: TextDirection.ltr, textAlign: TextAlign.center,
    )..layout(maxWidth: 60);
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  @override bool shouldRepaint(_) => false;
}

// ── Payment flow painter (Step 3) ──────────────────────────────────────────
class _PaymentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final boxW = s.width * .28;
    final boxH = 52.0;
    final cy   = s.height / 2;
    final xs   = [s.width * .08, s.width * .38, s.width * .68];
    final cols = [_kGold, _kAzure, const Color(0xFF34D399)];
    final lbls = ['VietQR', 'TripSync', 'MoMo'];
    final subs = ['Quet ma', 'Xu ly', 'Hoan tat'];

    for (var i = 0; i < 3; i++) {
      final rx = xs[i];
      // Box
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, cy - boxH / 2, boxW, boxH),
        const Radius.circular(12),
      );
      canvas.drawRRect(rr, Paint()..color = cols[i].withValues(alpha: .15));
      canvas.drawRRect(rr,
        Paint()..color = cols[i].withValues(alpha: .45)
          ..style = PaintingStyle.stroke..strokeWidth = 1.2);

      _drawCenteredText(canvas, lbls[i], Offset(rx + boxW / 2, cy - 10),
        cols[i], 12, FontWeight.w700);
      _drawCenteredText(canvas, subs[i], Offset(rx + boxW / 2, cy + 8),
        Colors.white38, 10, FontWeight.w400);

      // Arrow
      if (i < 2) {
        final ax = rx + boxW + 4;
        final ay = cy;
        canvas.drawLine(Offset(ax, ay), Offset(ax + s.width * .09, ay),
          Paint()..color = cols[i].withValues(alpha: .45)..strokeWidth = 1.2);
        // Arrowhead
        final tip = Offset(ax + s.width * .09, ay);
        final p = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - 7, tip.dy - 4)
          ..lineTo(tip.dx - 7, tip.dy + 4)
          ..close();
        canvas.drawPath(p, Paint()..color = cols[i].withValues(alpha: .45));
      }
    }

    // Step numbers
    for (var i = 0; i < 3; i++) {
      _drawCenteredText(canvas, '${i + 1}',
        Offset(xs[i] + boxW / 2, cy - boxH / 2 - 14),
        cols[i].withValues(alpha: .6), 10, FontWeight.w600);
    }
  }

  void _drawCenteredText(Canvas c, String txt, Offset center,
      Color col, double sz, FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(text: txt, style: TextStyle(color: col, fontSize: sz, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override bool shouldRepaint(_) => false;
}
