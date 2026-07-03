import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';

class InitialSetupScreen extends ConsumerStatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  ConsumerState<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  String _selectedCurrency = 'VND';
  final _balanceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      navigationBar: const CupertinoNavigationBar(middle: Text('Thiết lập')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          children: [
            Text('Thiết lập ban đầu', style: AppTheme.displayLg()),
            const SizedBox(height: 8),
            Text(
              'Chọn tiền tệ mặc định và số dư ban đầu để Miane hiển thị đúng cho chuyến đi.',
              style: AppTheme.bodyMd(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ).copyWith(height: 1.45),
            ),
            const SizedBox(height: 28),
            Text(
              'Tiền tệ mặc định',
              style: AppTheme.labelSm(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _selectedCurrency,
              children: const {
                'VND': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('VND'),
                ),
                'USD': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('USD'),
                ),
              },
              onValueChanged: (value) {
                if (value != null) setState(() => _selectedCurrency = value);
              },
            ),
            const SizedBox(height: 24),
            IosTextField(
              controller: _balanceController,
              label: 'Số dư ban đầu',
              placeholder: '0',
              prefixIcon: CupertinoIcons.money_dollar,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            IosPrimaryButton(
              label: 'Hoàn thành',
              onPressed: () =>
                  ref.read(appAuthProvider.notifier).completeSetup(),
            ),
          ],
        ),
      ),
    );
  }
}
