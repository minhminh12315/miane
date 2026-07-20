import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../controllers/app_auth_provider.dart';

enum _ForgotPasswordStep { email, reset }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ForgotPasswordStep _step = _ForgotPasswordStep.email;
  bool _isSending = false;
  bool _isResetting = false;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  String get _email => _emailController.text.trim();

  String get _maskedEmail {
    final parts = _email.split('@');
    if (parts.length != 2 || parts[0].length < 2) return _email;
    final name = parts[0];
    return '${name[0]}${'•' * (name.length - 2)}${name[name.length - 1]}@${parts[1]}';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> _sendOtp({bool resend = false}) async {
    if (_email.isEmpty) {
      await showIosMessage(
        context,
        message: 'Vui lòng nhập email tài khoản của bạn.',
        isError: true,
      );
      return;
    }

    if (resend && _resendCooldown > 0) return;

    setState(() => _isSending = true);
    try {
      await ref.read(appAuthProvider.notifier).sendPasswordResetOtp(_email);
      if (!mounted) return;

      setState(() {
        _step = _ForgotPasswordStep.reset;
        _otpController.clear();
      });
      _startResendCooldown();

      if (resend) {
        await showIosMessage(
          context,
          title: 'Đã gửi lại',
          message: 'Mã đặt lại mật khẩu đã được gửi đến $_maskedEmail.',
        );
      }
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Không thể gửi mã: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _resetPassword() async {
    final otpCode = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (otpCode.length != 6 || newPassword.isEmpty || confirmPassword.isEmpty) {
      await showIosMessage(
        context,
        message: 'Vui lòng nhập mã 6 số và mật khẩu mới.',
        isError: true,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      await showIosMessage(
        context,
        message: 'Mật khẩu xác nhận không khớp.',
        isError: true,
      );
      return;
    }

    setState(() => _isResetting = true);
    try {
      await ref.read(appAuthProvider.notifier).resetPassword(
            email: _email,
            otpCode: otpCode,
            newPassword: newPassword,
          );
      if (!mounted) return;

      await showIosMessage(
        context,
        title: 'Đã đổi mật khẩu',
        message: 'Bạn có thể đăng nhập bằng mật khẩu mới.',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
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
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isResetStep = _step == _ForgotPasswordStep.reset;

    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Quên mật khẩu'),
        previousPageTitle: 'Đăng nhập',
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          children: [
            IosAnimatedEntry(
              delay: 0,
              dy: 24,
              scaleBegin: 0.96,
              child: Text(
                isResetStep ? 'Đặt mật khẩu mới' : 'Khôi phục tài khoản',
                style: AppTheme.displayLg(),
              ),
            ),
            const SizedBox(height: 8),
            IosAnimatedEntry(
              delay: 0.06,
              child: Text(
                isResetStep
                    ? 'Nhập mã 6 số đã gửi đến $_maskedEmail và chọn mật khẩu mới.'
                    : 'Nhập email đã đăng ký để nhận mã đặt lại mật khẩu.',
                style: AppTheme.bodyMd(color: secondary),
              ),
            ),
            const SizedBox(height: 28),
            if (!isResetStep) ...[
              IosAnimatedEntry(
                delay: 0.14,
                child: IosTextField(
                  controller: _emailController,
                  label: 'Email',
                  placeholder: 'name@example.com',
                  prefixIcon: CupertinoIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 28),
              IosAnimatedEntry(
                delay: 0.22,
                dy: 24,
                child: IosPrimaryButton(
                  label: 'Gửi mã đặt lại',
                  isLoading: _isSending,
                  onPressed: () => _sendOtp(),
                ),
              ),
            ] else ...[
              IosAnimatedEntry(
                delay: 0.14,
                child: IosTextField(
                  controller: _otpController,
                  label: 'Mã xác minh',
                  placeholder: '6 chữ số',
                  prefixIcon: CupertinoIcons.number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              IosAnimatedEntry(
                delay: 0.22,
                child: IosTextField(
                  controller: _newPasswordController,
                  label: 'Mật khẩu mới',
                  placeholder: 'Ít nhất 6 ký tự, có số',
                  prefixIcon: CupertinoIcons.lock,
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 16),
              IosAnimatedEntry(
                delay: 0.30,
                child: IosTextField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  placeholder: 'Nhập lại mật khẩu mới',
                  prefixIcon: CupertinoIcons.lock,
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 24),
              IosAnimatedEntry(
                delay: 0.38,
                dy: 24,
                child: IosPrimaryButton(
                  label: 'Đặt lại mật khẩu',
                  isLoading: _isResetting,
                  onPressed: _resetPassword,
                ),
              ),
              const SizedBox(height: 12),
              IosAnimatedEntry(
                delay: 0.46,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _resendCooldown > 0 || _isSending
                      ? null
                      : () => _sendOtp(resend: true),
                  child: Text(
                    _isSending
                        ? 'Đang gửi...'
                        : _resendCooldown > 0
                            ? 'Gửi lại sau ${_resendCooldown}s'
                            : 'Gửi lại mã',
                    style: AppTheme.bodySm(
                      color: _resendCooldown > 0 || _isSending
                          ? secondary.withValues(alpha: 0.64)
                          : AppTheme.iosBlue,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
