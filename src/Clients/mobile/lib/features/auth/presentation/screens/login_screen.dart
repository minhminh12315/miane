import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../controllers/app_auth_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      await showIosMessage(
        context,
        message: 'Vui lòng điền đầy đủ email và mật khẩu.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(appAuthProvider.notifier).login(email, password);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        await showIosMessage(
          context,
          message:
              'Đăng nhập thất bại: ${e.toString().replaceAll('ApiException: ', '')}',
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
        middle: Text('Đăng nhập'),
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
              child: Text('Chào mừng trở lại', style: AppTheme.displayLg()),
            ),
            const SizedBox(height: 8),
            IosAnimatedEntry(
              delay: 0.06,
              child: Text(
                'Đăng nhập để tiếp tục quản lý các chuyến đi.',
                style: AppTheme.bodyMd(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 16),
            IosAnimatedEntry(
              delay: 0.22,
              child: IosTextField(
                controller: _passwordController,
                label: 'Mật khẩu',
                placeholder: 'Mật khẩu',
                prefixIcon: CupertinoIcons.lock,
                obscureText: true,
              ),
            ),
            const SizedBox(height: 8),
            IosAnimatedEntry(
              delay: 0.30,
              child: Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            IosAnimatedEntry(
              delay: 0.38,
              dy: 24,
              child: IosPrimaryButton(
                label: 'Đăng nhập',
                isLoading: _isLoading,
                onPressed: _login,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
