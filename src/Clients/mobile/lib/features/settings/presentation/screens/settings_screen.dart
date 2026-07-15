import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/ios_ui.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../../notification/presentation/screens/notification_history_screen.dart';
import '../controllers/payment_account_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'Tiếng Việt';
  String _region = 'Việt Nam (VND)';

  @override
  Widget build(BuildContext context) {
    final paymentAccount = ref.watch(paymentAccountProvider);
    final tierState = ref.watch(currentUserTierProvider);
    final isPro = tierState.valueOrNull != null && tierState.valueOrNull! >= 1;

    return CupertinoPageScaffold(
      backgroundColor: iosGroupedBackground(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Cài đặt'),
            previousPageTitle: 'Miane',
          ),
          SliverToBoxAdapter(
            child: IosSection(
              children: [
                IosListTile(
                  icon: CupertinoIcons.person,
                  title: isPro ? 'Thành viên VIP' : 'Khách du lịch',
                  subtitle: 'traveler@example.com',
                  value: isPro ? 'VIP' : 'CƠ BẢN',
                ),
                if (!isPro)
                  IosListTile(
                    icon: CupertinoIcons.star,
                    iconColor: AppTheme.iosGold,
                    title: 'Nâng cấp MIANE VIP',
                    subtitle:
                        'Lập lịch AI, quét hóa đơn AI và không giới hạn chuyến đi',
                    onTap: () =>
                        showIosProSheet(context, featureName: 'MIANE VIP'),
                  )
                else
                  const IosListTile(
                    icon: CupertinoIcons.check_mark_circled_solid,
                    iconColor: AppTheme.iosGreen,
                    title: 'MIANE VIP đang hoạt động',
                    subtitle: 'Không giới hạn chuyến đi và thành viên',
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Tài khoản và bản địa hóa',
              children: [
                IosListTile(
                  icon: CupertinoIcons.globe,
                  title: 'Ngôn ngữ hệ thống',
                  value: _language,
                  onTap: () => _showChoiceSheet(
                    title: 'Chọn ngôn ngữ',
                    values: const ['Tiếng Việt', 'English'],
                    current: _language,
                    onSelected: (value) => setState(() => _language = value),
                  ),
                ),
                IosListTile(
                  icon: CupertinoIcons.location,
                  title: 'Quốc gia / Vùng',
                  value: _region,
                  onTap: () => _showChoiceSheet(
                    title: 'Chọn quốc gia / vùng',
                    values: const ['Việt Nam (VND)', 'Mỹ (USD)'],
                    current: _region,
                    onSelected: (value) => setState(() => _region = value),
                  ),
                ),
                IosListTile(
                  icon: CupertinoIcons.creditcard,
                  title: 'Ví nhận tiền',
                  subtitle: paymentAccount.displaySubtitle,
                  value: paymentAccount.displayValue,
                  onTap: () => _showWalletDialog(paymentAccount),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              header: 'Ứng dụng và hỗ trợ',
              children: [
                IosListTile(
                  icon: CupertinoIcons.bell,
                  title: 'Thông báo đẩy',
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                          builder: (_) => const NotificationHistoryScreen()),
                    );
                  },
                ),
                const IosListTile(
                  icon: CupertinoIcons.lock_shield,
                  title: 'Bảo mật và quyền riêng tư',
                ),
                const IosListTile(
                  icon: CupertinoIcons.question_circle,
                  title: 'Trợ giúp và phản hồi',
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: IosSection(
              children: [
                IosListTile(
                  icon: CupertinoIcons.square_arrow_right,
                  iconColor: AppTheme.iosRed,
                  title: 'Đăng xuất',
                  destructive: true,
                  onTap: () => ref.read(appAuthProvider.notifier).logout(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 132)),
        ],
      ),
    );
  }

  void _showChoiceSheet({
    required String title,
    required List<String> values,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: values.map((value) {
          return CupertinoActionSheetAction(
            isDefaultAction: value == current,
            onPressed: () {
              Navigator.of(context).pop();
              onSelected(value);
            },
            child: Text(value == current ? '$value ✓' : value),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  void _showWalletDialog(PaymentAccountConfig current) {
    final bankController = TextEditingController(text: current.bankName);
    final accountController =
        TextEditingController(text: current.accountNumber);
    final holderController = TextEditingController(text: current.accountHolder);

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Ví nhận tiền'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              IosTextField(
                controller: bankController,
                placeholder: 'Ngân hàng / Ví',
                prefixIcon: CupertinoIcons.creditcard,
              ),
              const SizedBox(height: 10),
              IosTextField(
                controller: holderController,
                placeholder: 'Tên chủ tài khoản',
                prefixIcon: CupertinoIcons.person,
              ),
              const SizedBox(height: 10),
              IosTextField(
                controller: accountController,
                placeholder: 'Số tài khoản / Số điện thoại',
                prefixIcon: CupertinoIcons.number,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final bankName = bankController.text.trim();
              final accountNumber = accountController.text.trim();
              if (bankName.isEmpty || accountNumber.isEmpty) {
                await showIosMessage(
                  dialogContext,
                  message: 'Vui lòng nhập ngân hàng/ví và số tài khoản.',
                  isError: true,
                );
                return;
              }
              await ref.read(paymentAccountProvider.notifier).save(
                    bankName: bankName,
                    accountNumber: accountNumber,
                    accountHolder: holderController.text,
                  );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
