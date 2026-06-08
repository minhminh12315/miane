import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
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
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _resendTimer;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _animController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2 || parts[0].length < 2) return widget.email;
    final name = parts[0];
    final masked = '${name[0]}${'•' * (name.length - 2)}${name[name.length - 1]}';
    return '$masked@${parts[1]}';
  }

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length != 6) return;

    setState(() => _isVerifying = true);
    try {
      await ref.read(appAuthProvider.notifier).verifyRegistrationOtp(widget.email, code);
      if (context.mounted) {
        // Pop all auth screens back to root (which will now show MainLayoutScreen)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
        // Clear OTP fields on error
        for (final c in _otpControllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi lại mã xác minh đến ${_maskedEmail}'),
            backgroundColor: AppTheme.iosBlue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi lại thất bại: ${e.toString().replaceAll('ApiException: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kDark = AppTheme.canvasDark;
    const Color kNavy = AppTheme.surfaceDark;
    const Color kAzure = AppTheme.iosBlue;
    const Color kGold = AppTheme.iosGold;
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
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [kNavy, kAzure],
                      ),
                      border: Border.all(
                        color: kAzure.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mail_outline_rounded,
                        color: kGold,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Xác minh email',
                    style: GoogleFonts.inter(
                      color: kLight,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chúng tôi đã gửi mã 6 số đến',
                    style: GoogleFonts.beVietnamPro(
                      color: kLight.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _maskedEmail,
                    style: GoogleFonts.beVietnamPro(
                      color: kAzure,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // OTP Input Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 48,
                        height: 56,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 0 : (index == 3 ? 16 : 8),
                        ),
                        decoration: BoxDecoration(
                          color: kNavy,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _otpControllers[index].text.isNotEmpty
                                ? kAzure
                                : kAzure.withValues(alpha: 0.25),
                            width: _otpControllers[index].text.isNotEmpty ? 1.5 : 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: GoogleFonts.inter(
                            color: kLight,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            setState(() {});
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            }
                            // Auto-submit when all 6 digits are entered
                            if (_otpCode.length == 6) {
                              _verifyOtp();
                            }
                          },
                          onTap: () {
                            _otpControllers[index].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _otpControllers[index].text.length,
                            );
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Verify Button
                  GestureDetector(
                    onTap: _isVerifying ? null : _verifyOtp,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _otpCode.length == 6 ? kAzure : kAzure.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _otpCode.length == 6
                            ? [
                                BoxShadow(
                                  color: kAzure.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: kLight,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Xác minh',
                                style: GoogleFonts.beVietnamPro(
                                  color: kLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Không nhận được mã? ',
                        style: GoogleFonts.beVietnamPro(
                          color: kLight.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: _resendCooldown > 0 ? null : _resendOtp,
                        child: _isResending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: kAzure,
                                  strokeWidth: 1.5,
                                ),
                              )
                            : Text(
                                _resendCooldown > 0
                                    ? 'Gửi lại (${_resendCooldown}s)'
                                    : 'Gửi lại',
                                style: GoogleFonts.beVietnamPro(
                                  color: _resendCooldown > 0
                                      ? kLight.withValues(alpha: 0.3)
                                      : kAzure,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
