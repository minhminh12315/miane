import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../controllers/app_auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String password;
  final String fullName;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  late final AnimationController _loopController;

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _resendTimer;

  String get _otpCode =>
      _otpControllers.map((controller) => controller.text).join();

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2 || parts[0].length < 2) return widget.email;
    final name = parts[0];
    return '${name[0]}${'•' * (name.length - 2)}${name[name.length - 1]}@${parts[1]}';
  }

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendCooldown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _loopController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length != 6 || _isVerifying) return;

    setState(() => _isVerifying = true);
    try {
      await ref
          .read(appAuthProvider.notifier)
          .verifyRegistrationOtp(widget.email, code);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        for (final controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes.first.requestFocus();
        await showIosMessage(
          context,
          message: e
              .toString()
              .replaceAll('ApiException: ', '')
              .replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      await ref.read(appAuthProvider.notifier).sendRegistrationOtp(
            widget.email,
            widget.password,
            widget.fullName,
          );
      _startResendCooldown();
      if (mounted) {
        await showIosMessage(
          context,
          title: 'Đã gửi lại',
          message: 'Mã xác minh đã được gửi đến $_maskedEmail.',
        );
      }
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Gửi lại thất bại: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.canvasDark,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.canvasDark.withValues(alpha: 0.72),
        border: null,
        middle: const Text('Xác minh email'),
        previousPageTitle: 'Đăng ký',
      ),
      child: AnimatedBuilder(
        animation: _loopController,
        builder: (context, _) {
          final loop = _loopController.value;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OtpBackdropPainter(progress: loop),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: IosAnimatedEntry(
                                delay: 0,
                                dy: 28,
                                scaleBegin: 0.96,
                                child: ModernGlass(
                                  radius: 34,
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 28, 18, 22),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _MailVerificationBadge(progress: loop),
                                      const SizedBox(height: 24),
                                      IosAnimatedEntry(
                                        delay: 0.06,
                                        child: Text(
                                          'Nhập mã 6 số',
                                          textAlign: TextAlign.center,
                                          style: AppTheme.displayLg(),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      IosAnimatedEntry(
                                        delay: 0.12,
                                        child: Text(
                                          'Chúng tôi đã gửi mã xác minh đến $_maskedEmail.',
                                          textAlign: TextAlign.center,
                                          style:
                                              AppTheme.bodyMd(color: secondary)
                                                  .copyWith(height: 1.45),
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      _OtpInputRow(
                                        controllers: _otpControllers,
                                        focusNodes: _focusNodes,
                                        onChanged: (index, value) {
                                          setState(() {});
                                          if (value.isNotEmpty && index < 5) {
                                            _focusNodes[index + 1]
                                                .requestFocus();
                                          }
                                          if (_otpCode.length == 6) {
                                            _verifyOtp();
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 22),
                                      _OtpProgress(
                                        value: _otpCode.length / 6,
                                      ),
                                      const SizedBox(height: 26),
                                      IosAnimatedEntry(
                                        delay: 0.42,
                                        dy: 20,
                                        child: IosPrimaryButton(
                                          label: 'Xác minh',
                                          isLoading: _isVerifying,
                                          onPressed: _otpCode.length == 6
                                              ? _verifyOtp
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      IosAnimatedEntry(
                                        delay: 0.50,
                                        child: CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: _resendCooldown > 0 ||
                                                  _isResending
                                              ? null
                                              : _resendOtp,
                                          child: Text(
                                            _isResending
                                                ? 'Đang gửi lại...'
                                                : _resendCooldown > 0
                                                    ? 'Gửi lại sau ${_resendCooldown}s'
                                                    : 'Gửi lại mã',
                                            style: AppTheme.bodySm(
                                              color: _resendCooldown > 0 ||
                                                      _isResending
                                                  ? secondary.withValues(
                                                      alpha: 0.64,
                                                    )
                                                  : AppTheme.iosBlue,
                                            ),
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
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MailVerificationBadge extends StatelessWidget {
  final double progress;

  const _MailVerificationBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(progress * math.pi * 2);

    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PulseRingPainter(progress: progress),
            ),
          ),
          Transform.translate(
            offset: Offset(0, wave * 4),
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3CC8FF),
                    AppTheme.iosBlue,
                    AppTheme.iosIndigo,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: CupertinoColors.white.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.iosBlue.withValues(alpha: 0.42),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.mail,
                color: CupertinoColors.white,
                size: 36,
              ),
            ),
          ),
          Positioned(
            right: 19,
            bottom: 20,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: AppTheme.iosGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.canvasDark, width: 3),
              ),
              child: const Icon(
                CupertinoIcons.check_mark,
                color: CupertinoColors.black,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpInputRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  const _OtpInputRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final availableWidth = math.min(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360, 360.0);
        final rawWidth = (availableWidth - gap * 5) / 6;
        final boxWidth = rawWidth.clamp(42.0, 54.0).toDouble();
        final boxHeight = (boxWidth + 8).clamp(52.0, 60.0).toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return IosAnimatedEntry(
              delay: 0.20 + index * 0.035,
              dy: 18,
              scaleBegin: 0.86,
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : gap),
                child: _OtpBox(
                  width: boxWidth,
                  height: boxHeight,
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  onChanged: (value) => onChanged(index, value),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _OtpProgress extends StatelessWidget {
  final double value;

  const _OtpProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        height: 5,
        width: 112,
        color: CupertinoColors.white.withValues(alpha: 0.08),
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          widthFactor: progress,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.iosBlue,
                  AppTheme.iosGreen,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        final hasValue = controller.text.isNotEmpty;
        final accent = hasValue ? AppTheme.iosGreen : AppTheme.iosBlue;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isFocused
                ? AppTheme.surfaceSecondaryDark.withValues(alpha: 0.96)
                : AppTheme.surfaceDark.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isFocused || hasValue)
                  ? accent.withValues(alpha: 0.72)
                  : CupertinoColors.white.withValues(alpha: 0.07),
              width: isFocused ? 1.4 : 0.7,
            ),
            boxShadow: [
              if (isFocused || hasValue)
                BoxShadow(
                  color: accent.withValues(alpha: isFocused ? 0.28 : 0.16),
                  blurRadius: isFocused ? 18 : 10,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            cursorHeight: 24,
            cursorColor: AppTheme.iosBlue,
            style: const TextStyle(
              color: AppTheme.iosLight,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
            strutStyle: const StrutStyle(
              fontSize: 24,
              height: 1,
              forceStrutHeight: true,
            ),
            padding: const EdgeInsets.only(bottom: 1),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const BoxDecoration(
              color: CupertinoColors.transparent,
            ),
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  final double progress;

  const _PulseRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1;
      final radius = 34 + phase * 28;
      paint.color = AppTheme.iosBlue.withValues(alpha: (1 - phase) * 0.20);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _OtpBackdropPainter extends CustomPainter {
  final double progress;

  const _OtpBackdropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final t = progress * math.pi * 2;

    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.canvasDark);

    void glow({
      required Offset center,
      required double radius,
      required List<Color> colors,
    }) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: colors).createShader(
            Rect.fromCircle(center: center, radius: radius),
          ),
      );
    }

    glow(
      center: Offset(width * (0.14 + math.sin(t) * 0.03), height * 0.18),
      radius: width * 0.48,
      colors: [
        AppTheme.iosBlue.withValues(alpha: 0.26),
        AppTheme.iosIndigo.withValues(alpha: 0.08),
        CupertinoColors.transparent,
      ],
    );
    glow(
      center: Offset(width * (0.88 + math.cos(t * 0.8) * 0.03), height * 0.70),
      radius: width * 0.52,
      colors: [
        AppTheme.iosGreen.withValues(alpha: 0.16),
        AppTheme.iosBlue.withValues(alpha: 0.08),
        CupertinoColors.transparent,
      ],
    );
    glow(
      center: Offset(width * (0.28 + math.sin(t * 0.7) * 0.04), height * 0.86),
      radius: width * 0.42,
      colors: [
        AppTheme.iosPink.withValues(alpha: 0.14),
        AppTheme.iosOrange.withValues(alpha: 0.07),
        CupertinoColors.transparent,
      ],
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = CupertinoColors.white.withValues(alpha: 0.035);
    for (var i = 0; i < 6; i++) {
      final y = height * (0.22 + i * 0.11) + math.sin(t + i) * 4;
      final path = Path()
        ..moveTo(20, y)
        ..cubicTo(
          width * 0.30,
          y - 18,
          width * 0.70,
          y + 18,
          width - 20,
          y,
        );
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OtpBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
