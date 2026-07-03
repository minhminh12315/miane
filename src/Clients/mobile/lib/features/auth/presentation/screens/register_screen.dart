import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../controllers/app_auth_provider.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      await showIosMessage(context,
          message: 'Vui lòng điền đầy đủ thông tin.', isError: true);
      return;
    }

    if (password != confirmPassword) {
      await showIosMessage(context,
          message: 'Mật khẩu xác nhận không khớp.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(appAuthProvider.notifier).sendRegistrationOtp(
            email,
            password,
            fullName,
          );
      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: email,
              password: password,
              fullName: fullName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Gửi mã xác minh thất bại: ${e.toString().replaceAll('ApiException: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Tạo tài khoản'),
        previousPageTitle: 'Miane',
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          children: [
            IosAnimatedEntry(
              delay: 0,
              dy: 24,
              scaleBegin: 0.96,
              child: Text('Bắt đầu với Miane', style: AppTheme.displayLg()),
            ),
            const SizedBox(height: 8),
            IosAnimatedEntry(
              delay: 0.06,
              child: Text(
                'Tài khoản giúp đồng bộ chuyến đi, thành viên và chi tiêu.',
                style: AppTheme.bodyMd(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(height: 28),
            IosAnimatedEntry(
              delay: 0.14,
              child: IosTextField(
                controller: _nameController,
                label: 'Họ và tên',
                placeholder: 'Nguyễn Văn A',
                prefixIcon: CupertinoIcons.person,
              ),
            ),
            const SizedBox(height: 16),
            IosAnimatedEntry(
              delay: 0.22,
              child: IosTextField(
                controller: _emailController,
                label: 'Email',
                placeholder: 'name@example.com',
                prefixIcon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 16),
            IosAnimatedEntry(
              delay: 0.30,
              child: IosTextField(
                controller: _passwordController,
                label: 'Mật khẩu',
                placeholder: 'Mật khẩu',
                prefixIcon: CupertinoIcons.lock,
                obscureText: true,
              ),
            ),
            const SizedBox(height: 16),
            IosAnimatedEntry(
              delay: 0.38,
              child: IosTextField(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                placeholder: 'Nhập lại mật khẩu',
                prefixIcon: CupertinoIcons.lock,
                obscureText: true,
              ),
            ),
            const SizedBox(height: 28),
            IosAnimatedEntry(
              delay: 0.48,
              dy: 24,
              child: IosPrimaryButton(
                label: 'Gửi mã xác minh',
                isLoading: _isLoading,
                onPressed: _register,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
