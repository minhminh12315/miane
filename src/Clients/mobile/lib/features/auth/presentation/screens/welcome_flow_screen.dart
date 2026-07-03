import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../controllers/app_auth_provider.dart';

part 'welcome_flow_screen.g.dart';

@riverpod
class WelcomeFlowPageIndex extends _$WelcomeFlowPageIndex {
  @override
  int build() => 0;

  void setPage(int index) {
    state = index;
  }
}

class WelcomeFlowScreen extends ConsumerStatefulWidget {
  const WelcomeFlowScreen({super.key});

  @override
  ConsumerState<WelcomeFlowScreen> createState() => _WelcomeFlowScreenState();
}

class _WelcomeFlowScreenState extends ConsumerState<WelcomeFlowScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _introController;
  late final AnimationController _liquidController;

  double _pageValue = 0;

  static const _steps = [
    _WelcomeStep(
      icon: CupertinoIcons.map_fill,
      title: 'Du lịch gọn hơn',
      body: 'Tạo chuyến đi, mời bạn bè và gom mọi khoản chi vào một nơi.',
      accent: AppTheme.iosOrange,
      gradient: [Color(0xFF4A2D1D), Color(0xFF17142E), Color(0xFF050505)],
      routeFrom: 'HAN',
      routeTo: 'DAD',
      routeLabel: 'Trip Plan',
    ),
    _WelcomeStep(
      icon: CupertinoIcons.money_dollar_circle_fill,
      title: 'Chia tiền rõ ràng',
      body: 'Theo dõi ai đã trả, ai cần thanh toán và số dư quỹ nhóm.',
      accent: AppTheme.iosBlue,
      gradient: [Color(0xFF0E3A55), Color(0xFF11182C), Color(0xFF050505)],
      routeFrom: 'PAY',
      routeTo: 'SPLIT',
      routeLabel: 'Expenses',
    ),
    _WelcomeStep(
      icon: CupertinoIcons.sparkles,
      title: 'Sẵn sàng cho chuyến mới',
      body:
          'MIANE giữ phần tài chính nhẹ nhàng để bạn tập trung tận hưởng hành trình.',
      accent: AppTheme.iosPink,
      gradient: [Color(0xFF4B1230), Color(0xFF18143A), Color(0xFF050505)],
      routeFrom: 'GO',
      routeTo: 'DONE',
      routeLabel: 'Assistant',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController()
      ..addListener(() {
        final page =
            _pageController.page ?? _pageController.initialPage.toDouble();
        if (page != _pageValue) setState(() => _pageValue = page);
      });

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5400),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _introController.dispose();
    _liquidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(welcomeFlowPageIndexProvider);

    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      child: AnimatedBuilder(
        animation: Listenable.merge([_introController, _liquidController]),
        builder: (context, _) {
          final intro = Curves.easeOutCubic.transform(_introController.value);
          final liquid = _liquidController.value;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LiquidBackgroundPainter(
                    progress: liquid,
                    pageValue: _pageValue,
                  ),
                ),
              ),
              ModernPage(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: _SkipButton(
                            intro: intro,
                            onPressed: () => ref
                                .read(appAuthProvider.notifier)
                                .completeWelcome(),
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _steps.length,
                            onPageChanged: (index) {
                              ref
                                  .read(welcomeFlowPageIndexProvider.notifier)
                                  .setPage(index);
                            },
                            itemBuilder: (context, index) {
                              return _WelcomePage(
                                step: _steps[index],
                                index: index,
                                pageValue: _pageValue,
                                intro: intro,
                                liquid: liquid,
                              );
                            },
                          ),
                        ),
                        _BottomControls(
                          count: _steps.length,
                          currentPage: currentPage,
                          liquid: liquid,
                          onContinue: () {
                            if (currentPage == _steps.length - 1) {
                              ref
                                  .read(appAuthProvider.notifier)
                                  .completeWelcome();
                              return;
                            }
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 540),
                              curve: Curves.easeOutCubic,
                            );
                          },
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

class _WelcomeStep {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final List<Color> gradient;
  final String routeFrom;
  final String routeTo;
  final String routeLabel;

  const _WelcomeStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.gradient,
    required this.routeFrom,
    required this.routeTo,
    required this.routeLabel,
  });
}

class _WelcomePage extends StatelessWidget {
  final _WelcomeStep step;
  final int index;
  final double pageValue;
  final double intro;
  final double liquid;

  const _WelcomePage({
    required this.step,
    required this.index,
    required this.pageValue,
    required this.intro,
    required this.liquid,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;
    final offset = (pageValue - index).clamp(-1.0, 1.0);
    final distance = offset.abs();
    final pageOpacity = (1 - distance * 0.38).clamp(0.0, 1.0);
    final entrance = _interval(intro, 0.0, 0.86);
    final titleEntrance = _interval(intro, 0.12, 0.76);
    final visualEntrance = _interval(intro, 0.22, 0.98);
    final actionEntrance = _interval(intro, 0.36, 1.0);
    final floatY = math.sin((liquid + index * 0.21) * math.pi * 2) * 8;
    final tilt = -offset * 0.055 + math.sin(liquid * math.pi * 2) * 0.006;

    return Opacity(
      opacity: pageOpacity,
      child: Transform.translate(
        offset: Offset(-offset * 26, 26 * (1 - entrance)),
        child: Transform.scale(
          scale: 0.94 + entrance * 0.06 - distance * 0.035,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(tilt),
              child: ModernCard(
                radius: 38,
                padding: EdgeInsets.zero,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: step.gradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -60 + floatY,
                      right: -54 - offset * 20,
                      child: _LiquidOrb(
                        size: 180,
                        color: step.accent,
                        alpha: 0.24,
                      ),
                    ),
                    Positioned(
                      bottom: 116 - floatY,
                      left: -76 + offset * 28,
                      child: const _LiquidOrb(
                        size: 170,
                        color: AppTheme.iosBlue,
                        alpha: 0.16,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 20 : 26,
                        compact ? 22 : 30,
                        compact ? 20 : 26,
                        compact ? 18 : 26,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Entrance(
                            value: titleEntrance,
                            y: 18,
                            child: Text(
                              'MIANE',
                              style: AppTheme.labelSm(color: AppTheme.iosOrange)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Entrance(
                            value: titleEntrance,
                            y: 24,
                            child: Text(
                              step.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 36,
                                height: 1.04,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ).copyWith(fontSize: compact ? 30 : 36),
                            ),
                          ),
                          SizedBox(height: compact ? 10 : 16),
                          _Entrance(
                            value: _interval(intro, 0.22, 0.82),
                            y: 18,
                            child: Text(
                              step.body,
                              maxLines: compact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyMd(
                                color: CupertinoColors.white
                                    .withValues(alpha: 0.72),
                              ).copyWith(height: 1.45),
                            ),
                          ),
                          const Spacer(),
                          _Entrance(
                            value: visualEntrance,
                            y: 34,
                            child: Center(
                              child: Transform.translate(
                                offset: Offset(offset * 32, floatY),
                                child: SizedBox(
                                  width: compact ? 154 : 238,
                                  height: compact ? 200 : 310,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: _PhoneTravelMock(
                                      step: step,
                                      progress: liquid,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!compact) ...[
                            const Spacer(),
                            _Entrance(
                              value: actionEntrance,
                              y: 18,
                              child: _ActionDock(step: step),
                            ),
                          ],
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
    );
  }
}

class _PhoneTravelMock extends StatelessWidget {
  final _WelcomeStep step;
  final double progress;

  const _PhoneTravelMock({
    required this.step,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + math.sin(progress * math.pi * 2) * 0.5;

    return Container(
      width: 238,
      height: 310,
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(42),
        border:
            Border.all(color: CupertinoColors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: step.accent.withValues(alpha: 0.18 + pulse * 0.08),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      step.accent.withValues(alpha: 0.32),
                      AppTheme.surfaceElevated,
                      AppTheme.surfaceDark,
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 9),
                  width: 72,
                  height: 22,
                  decoration: BoxDecoration(
                    color: CupertinoColors.black,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 44, 14, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _MockCircle(
                            icon: CupertinoIcons.ellipsis, color: step.accent),
                        const SizedBox(width: 8),
                        const _MockCircle(
                            icon: CupertinoIcons.search,
                            color: AppTheme.iosLight),
                        const Spacer(),
                        const _MockCircle(
                            icon: CupertinoIcons.xmark,
                            color: AppTheme.iosLight),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _MockRouteCard(step: step, progress: progress),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ModernGlass(
                        radius: 24,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(step.icon, color: step.accent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  step.routeLabel,
                                  style: AppTheme.titleSm(),
                                ),
                                const Spacer(),
                                Text(
                                  'Today',
                                  style: AppTheme.bodySm(
                                    color: CupertinoColors.white
                                        .withValues(alpha: 0.48),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const _TimelineRow(
                              icon: CupertinoIcons.sun_max_fill,
                              color: AppTheme.iosGold,
                              text: '18° / 27° • Đà Nẵng',
                              time: 'Now',
                            ),
                            _TimelineRow(
                              icon: CupertinoIcons.airplane,
                              color: AppTheme.iosBlue,
                              text: '${step.routeFrom} → ${step.routeTo}',
                              time: '09:41',
                            ),
                            const _TimelineRow(
                              icon: CupertinoIcons.creditcard_fill,
                              color: AppTheme.iosPink,
                              text: 'Split ready',
                              time: 'Auto',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockCircle extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MockCircle({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _MockRouteCard extends StatelessWidget {
  final _WelcomeStep step;
  final double progress;

  const _MockRouteCard({
    required this.step,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RouteText(
              label: 'From',
              value: step.routeFrom,
              alignEnd: false,
            ),
          ),
          SizedBox(
            width: 74,
            height: 44,
            child: CustomPaint(
              painter: _RouteLinePainter(
                color: step.accent,
                progress: progress,
              ),
            ),
          ),
          Expanded(
            child: _RouteText(
              label: 'To',
              value: step.routeTo,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteText extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _RouteText({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTheme.labelXs(
            color: CupertinoColors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String time;

  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySm(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: AppTheme.labelSm(
              color: CupertinoColors.white.withValues(alpha: 0.46),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionDock extends StatelessWidget {
  final _WelcomeStep step;

  const _ActionDock({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ModernActionCircle(
            icon: CupertinoIcons.airplane,
            label: 'Flights',
            color: step.accent,
          ),
        ),
        const Expanded(
          child: ModernActionCircle(
            icon: CupertinoIcons.bed_double,
            label: 'Stay',
            color: AppTheme.iosLight,
          ),
        ),
        const Expanded(
          child: ModernActionCircle(
            icon: CupertinoIcons.money_dollar,
            label: 'Split',
            color: AppTheme.iosGold,
          ),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int count;
  final int currentPage;
  final double liquid;
  final VoidCallback onContinue;

  const _BottomControls({
    required this.count,
    required this.currentPage,
    required this.liquid,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Dots(count: count, current: currentPage),
        const Spacer(),
        _ContinueButton(
          label: currentPage == count - 1 ? 'Bắt đầu' : 'Tiếp tục',
          liquid: liquid,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final double liquid;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.label,
    required this.liquid,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + math.sin(liquid * math.pi * 2) * 0.5;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 14, 11),
        decoration: BoxDecoration(
          color: AppTheme.iosBlue.withValues(alpha: 0.18 + pulse * 0.08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: AppTheme.iosBlue.withValues(alpha: 0.28 + pulse * 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.iosBlue.withValues(alpha: 0.18 + pulse * 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.bodyMd(color: CupertinoColors.white)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.arrow_right,
              color: CupertinoColors.white,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final double intro;
  final VoidCallback onPressed;

  const _SkipButton({
    required this.intro,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _interval(intro, 0.35, 1),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: const Text('Xong'),
      ),
    );
  }
}

class _Entrance extends StatelessWidget {
  final double value;
  final double y;
  final Widget child;

  const _Entrance({
    required this.value,
    required this.y,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(value.clamp(0, 1));
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * y),
        child: child,
      ),
    );
  }
}

class _LiquidOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _LiquidOrb({
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: alpha),
            blurRadius: 56,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;

  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final active = current == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: active ? 26 : 7,
          height: 7,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.iosBlue
                : CupertinoColors.systemGrey.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  final Color color;
  final double progress;

  const _RouteLinePainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final start = Offset(4, y);
    final end = Offset(size.width - 4, y);
    final basePaint = Paint()
      ..color = CupertinoColors.white.withValues(alpha: 0.16)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, basePaint);
    canvas.drawLine(
      start,
      Offset(4 + (size.width - 8) * progress, y),
      activePaint,
    );

    final planeX = 4 + (size.width - 8) * progress;
    final planeCenter = Offset(planeX, y);
    final iconPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(planeCenter.dx + 8, planeCenter.dy)
      ..lineTo(planeCenter.dx - 7, planeCenter.dy - 7)
      ..lineTo(planeCenter.dx - 3, planeCenter.dy)
      ..lineTo(planeCenter.dx - 7, planeCenter.dy + 7)
      ..close();
    canvas.drawPath(path, iconPaint);
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _LiquidBackgroundPainter extends CustomPainter {
  final double progress;
  final double pageValue;

  const _LiquidBackgroundPainter({
    required this.progress,
    required this.pageValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF060606),
          Color(0xFF090A16),
          Color(0xFF000000),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final colors = [
      AppTheme.iosOrange,
      AppTheme.iosBlue,
      AppTheme.iosPink,
    ];
    for (var i = 0; i < 3; i++) {
      final phase = progress * math.pi * 2 + i * 1.7 + pageValue * 0.42;
      final center = Offset(
        size.width * (0.2 + i * 0.28) + math.sin(phase) * 34,
        size.height * (0.18 + i * 0.2) + math.cos(phase * 0.8) * 44,
      );
      final orbPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 58);
      canvas.drawCircle(center, 116 + i * 24, orbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pageValue != pageValue;
  }
}

double _interval(double value, double start, double end) {
  if (value <= start) return 0;
  if (value >= end) return 1;
  return ((value - start) / (end - start)).clamp(0.0, 1.0);
}
